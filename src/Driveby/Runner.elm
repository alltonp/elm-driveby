module Driveby.Runner exposing (run)

import Driveby exposing (..)
import Driveby.Model exposing (..)
import Driveby.Runner.Model exposing (..)
import Date exposing (..)
import Task
import Dict exposing (..)
import Html exposing (..)


--import Html.App as App

import Maybe.Extra as MaybeExtra


--TODO: figure out why finished isnt populated with the datetime
--TODO: think about a test suite for ourselves, could stub the html coming back (just like in scala driveby)


run : Suite -> (Request -> Cmd Msg) -> ((Response -> Msg) -> Sub Msg) -> Program Flags Model Msg
run suite requestsPort responsesPort =
    Html.programWithFlags
        { init = init suite
        , view = view
        , update = update requestsPort
        , subscriptions = subscriptions responsesPort
        }


init : Suite -> Flags -> ( Model, Cmd Msg )
init suite flags =
    --TODO: asFx log (thePlan) ...
    --TODO: do any filtering here .. e.g. filter scripts/suite name from flags ..
    --TODO: might ultimately need List Suite ...
    ( Model flags Dict.empty (buildScriptIdToExecutableScript suite.scripts), runAllScripts )



--TODO: we seem to do a lot of List.indexedMap then Dict.fromList etc .. make a help for it ...


buildScriptIdToExecutableScript : List Script -> Dict Int ExecutableScript
buildScriptIdToExecutableScript scripts =
    scripts
        |> List.indexedMap
            (\i script ->
                let
                    steps =
                        script.commands
                            |> List.indexedMap (,)
                            |> List.map (\( i, command ) -> Step i command False)
                in
                    ( i, ExecutableScript i script.name steps Nothing Nothing [] )
            )
        |> Dict.fromList


subscriptions : ((Response -> Msg) -> Sub Msg) -> Model -> Sub Msg
subscriptions responsesPort model =
    responsesPort Process


update : (Request -> Cmd Msg) -> Msg -> Model -> ( Model, Cmd Msg )
update requestsPort msg model =
    case msg of
        --TODO: store date or lose it ...
        --TODO: this could probably happen in init ...
        RunAllScripts startDate ->
            let
                d =
                    Debug.log "RunAllScripts " ((toString (List.length (Dict.keys model.scriptIdToExecutableScript)) ++ " " ++ (toString startDate) ++ " " ++ (toString model.flags)))

                cmds =
                    List.repeat model.flags.numberOfBrowsers 1
                        |> List.indexedMap (,)
                        |> List.map (\( i, r ) -> asFx (RunNextScript i ""))
            in
                ( model, Cmd.batch cmds )

        --This isnt really a good name, the intention is to start a script on browserId
        --but actually it runs the next available script on this browserId if there is one
        -- fix the implementation ...
        RunNextScript browserId theDate ->
            case nextUnstartedScript model of
                Just executableScript ->
                    let
                        updatedModel =
                            { model
                                | -- aka start script -- (need a corresponding stop script)
                                  -- mark browser as running this script
                                  browserIdToScriptId = Dict.update browserId (\v -> Just executableScript.id) model.browserIdToScriptId
                                , -- mark this script as started
                                  scriptIdToExecutableScript =
                                    Dict.update (executableScript.id)
                                        (\e -> Just { executableScript | started = Just theDate })
                                        model.scriptIdToExecutableScript
                            }
                    in
                        ( updatedModel, asFx (RunNextStep (Context -1 browserId executableScript.id 0 theDate)) )

                Nothing ->
                    ( model, Cmd.none )

        MainLoop context ->
            let
                --        d = Debug.log "MainLoop" (toString context)
                --TODO: I need fleshing out
                --BUG: test fails, but then carries on add passes, lol because next step will be run, it probably needs its
                --             finish flag to be set
                --      TODO: maybe Process is MainLoop actually ...
                --if failed then Exit this test
                --if more steps then RunNextStep
                --if no more steps then RunNextScript
                --if no more scripts then AllDone
                nextCmd =
                    asFx (RunNextStep { context | stepId = context.stepId + 1 })
            in
                ( model, nextCmd )

        --TODO: pretty sure this doesn't do just what it says on the tin ...
        RunNextStep context ->
            case currentScript context model of
                Just executableScript ->
                    let
                        cmd =
                            case nextStepToRun executableScript of
                                Just step ->
                                    let
                                        --TODO: keep this in on the elm side and have an debugTrace flag
                                        --                        d = Debug.log ("Driveby " ++ ( (toString context.localPort) ++ " " ++ (toString context.browserId) ++ " " ++ (toString step.id) ++ ": " ++ step.command.name ++ " " ++ (toString step.command.args) )) ""
                                        a =
                                            ""
                                    in
                                        ( model, requestsPort (Request context step) )

                                --TODO: this is defo wrong, we should'nt have even hit RunNext, should have bailed in Process
                                Nothing ->
                                    let
                                        --TODO: this is redundant in the failure case case
                                        --aka: mark script as finished
                                        updatedExecutableScript =
                                            { executableScript | finished = Just context.updated }

                                        updatedScriptIdToExecutableScript =
                                            Dict.update executableScript.id (\e -> Just updatedExecutableScript) model.scriptIdToExecutableScript

                                        --TODO: this should be in MainLoop
                                        cmd =
                                            if List.isEmpty executableScript.failures then
                                                asFx (ScriptFinished ("- " ++ executableScript.name) context)
                                            else
                                                asFx
                                                    (ScriptFinished
                                                        ("☒ " ++ executableScript.name ++ " " ++ (toString executableScript.failures))
                                                        context
                                                    )
                                    in
                                        ( { model | scriptIdToExecutableScript = updatedScriptIdToExecutableScript }, cmd )
                    in
                        cmd

                Nothing ->
                    ( model, Cmd.none )

        Process response ->
            case currentScript response.context model of
                Just executableScript ->
                    let
                        --                d = Debug.log "Process" (toString response)
                        --used? debug only?
                        --                currentStep = List.filter (\s -> s.id == response.context.stepId) executableScript.steps
                        -- aka: all of this mark this step as executed ... and aka: mark script as finished
                        updatedSteps =
                            List.map
                                (\s ->
                                    if s.id == response.context.stepId then
                                        Step s.id s.command True
                                    else
                                        s
                                )
                                executableScript.steps

                        --TODO: this might be the wrong place to do this now ... also in RNS
                        updatedFinished =
                            if List.isEmpty response.failures then
                                Nothing
                            else
                                Just response.context.updated

                        updatedExecutableScript =
                            { executableScript | steps = updatedSteps, finished = updatedFinished, failures = response.failures }

                        scriptId =
                            response.context.scriptId

                        updatedScriptIdToExecutableScript =
                            Dict.update scriptId (\e -> Just updatedExecutableScript) model.scriptIdToExecutableScript

                        updatedModel =
                            { model | scriptIdToExecutableScript = updatedScriptIdToExecutableScript }

                        --                TODO: send ScriptFailed if response has failures - seems like a good place to do this ... (if we need it ..)
                        --                2011-10-05T14:48:00.000Z
                        --                clearlyWrongDate = unsafeFromString "2016-06-17T11:15:00+0200"
                    in
                        ( updatedModel, asFx (MainLoop response.context) )

                --TODO: feels like this should be debug.crash because how could we get here, programming error?
                Nothing ->
                    ( model, Cmd.none )

        --TODO: do we need ScriptFailed, ScriptSucceeded?
        --TODO: currently this isnt doing much for us, logging and closing at end ...
        --TODO: the useful thing it could be doing is marking the script finished! (and removing from the browserId's)
        ScriptFinished message context ->
            let
                --TODO: this renders strangely, lets do in js instead ...
                d =
                    Debug.log ("Driveby " ++ message) ""

                --TODO: this should be in MainLoop
                --        d2 = Debug.log "Driveby scriptsThatNeedToStart: " ((toString (List.length scriptsThatNeedToStart)))
                --        d3 = Debug.log "Driveby scriptsThatNeedToFinish: " ((toString (List.length scriptsThatNeedToFinish)))
                cmd =
                    if not (List.isEmpty (scriptsThatNeedToStart model)) then
                        asFx (RunNextScript context.browserId context.updated)
                    else if not (List.isEmpty (scriptsThatNeedToFinish model)) then
                        Cmd.none
                        --TODO: we should be updating the context.stepId whenever we send it through requestsPort or (MainLopp)
                        --TODO: we shouldnt have to hardcode this 999 either ..
                        --TODO: should be an AllDone me thinks ...
                    else
                        (requestsPort (Request context (Step 999 close False)))
            in
                ( model, cmd )


currentScript : Context -> Model -> Maybe ExecutableScript
currentScript context model =
    let
        scriptId =
            Dict.get context.browserId model.browserIdToScriptId
    in
        Dict.get (Maybe.withDefault -1 scriptId) model.scriptIdToExecutableScript


nextUnstartedScript : Model -> Maybe ExecutableScript
nextUnstartedScript model =
    Dict.values model.scriptIdToExecutableScript |> List.filter (\s -> s.started == Nothing) |> List.head


nextStepToRun : ExecutableScript -> Maybe Step
nextStepToRun executableScript =
    if MaybeExtra.isNothing executableScript.finished then
        List.filter (\s -> not s.executed) executableScript.steps |> List.head
    else
        Nothing


scriptsThatNeedToStart : Model -> List ExecutableScript
scriptsThatNeedToStart model =
    Dict.values model.scriptIdToExecutableScript |> List.filter (\s -> s.started == Nothing)


scriptsThatNeedToFinish : Model -> List ExecutableScript
scriptsThatNeedToFinish model =
    Dict.values model.scriptIdToExecutableScript |> List.filter (\s -> s.finished == Nothing)



----------


view : Model -> Html Msg
view model =
    div [] []


close : Command
close =
    Command "close" []


asFx : msg -> Cmd msg
asFx msg =
    --    Task.perform (\_ -> Debug.crash "This failure cannot happen.")
    --        identity
    --        (Task.succeed msg)
    Task.perform
        --        (\_ -> Debug.crash "This failure cannot happen.")
        (\_ -> msg)
        --        identity
        (Task.succeed msg)



--TODO: maybe this can die now we are using JS


runAllScripts : Cmd Msg
runAllScripts =
    --    Task.perform (\_ -> Debug.crash "This failure cannot happen.")
    --        RunAllScripts
    --        Date.now
    Task.perform
        --        (\_ -> Debug.crash "This failure cannot happen.")
        RunAllScripts
        Date.now
