module Driveby.Runner exposing (Msg, Flags, init, update, view, subscriptions)


import Driveby.Model exposing (..)
import Date exposing (..)
import Task
import Dict exposing (..)
import Html exposing (..)


init : List Script -> Flags -> (Model, Cmd Msg)
init scripts flags =
   let
     scriptIdToExecutableScript = scripts
       |> List.indexedMap (\i s -> (i, ExecutableScript s i Nothing Nothing) )
       |> Dict.fromList
   in
     (Model (Config flags.browsers) Dict.empty scriptIdToExecutableScript, runAllScripts)


subscriptions : ((Response -> Msg) -> Sub Msg) -> Model -> Sub Msg
subscriptions responsesPort model =
  responsesPort Process


type alias Flags =
  { browsers : Int }


--TODO: can we not just use Flags instead?
type alias Config =
  { numberOfBrowsers : Int }


-- TODO: ultimately config isn't needed, they become browserIdToScriptId (mainly)
type alias Model =
  { config : Config
  , browserIdToScriptId : Dict Int Int
  , scriptIdToExecutableScript : Dict Int ExecutableScript
  }


type alias ExecutableScript =
  { script: Script
  , id : Int
  , started : Maybe String {-Date-}
  , finished : Maybe String {-Date-}
  }


--TODO: fix all this naming too
type Msg
  = RunAllScripts Date
  | RunNextScript Int String {-Date-}
  | RunNextStep Context
  | Process Response
  | MainLoop Context
  | ScriptFinished String Context

--TODO: add a Finish/AllDone (and do the reporting bit here ...)


update : (Request -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
update requestsPort msg model =
  case msg of
    --TODO: store date or lose it ...
    RunAllScripts startDate ->
      let
        d = Debug.log "RunAllScripts " ((toString (List.length (Dict.keys model.scriptIdToExecutableScript)) ++ " " ++ (toString startDate) ++ " " ++ (toString model.config)))

        cmds = List.repeat model.config.numberOfBrowsers 1
              |> List.indexedMap (,)
              |> List.map (\ (i,r) -> asFx (RunNextScript i "") )
      in
        ( model, Cmd.batch cmds )


    --This isnt really a good name, the intention is to start a script on browserId
    --but actually it runs the next available script on this browserId if there is one
    -- fix the implementation ...
    RunNextScript browserId theDate ->
      case nextUnstartedScript model of
        Just executableScript ->
          let
            model' = { model |
              -- mark browser as running this script
              browserIdToScriptId = Dict.update browserId (\v -> Just executableScript.id) model.browserIdToScriptId,
              -- mark this script as started
              scriptIdToExecutableScript = Dict.update (executableScript.id)
                (\e -> Just { executableScript | started = Just theDate } ) model.scriptIdToExecutableScript
             }
          in
            ( model', asFx (RunNextStep (Context -1 browserId executableScript.id 0 theDate)))

        Nothing ->
          (model, Cmd.none)


    MainLoop context ->
      let
        d = Debug.log "MainLoop" (toString context)

        nextCmd = asFx (RunNextStep { context | stepId = context.stepId + 1 } )
      in
        (model, nextCmd)


    --TODO: pretty sure this doesnt do just what it says on the tin ...
    RunNextStep context ->
        case currentScript context model of
            Just executableScript ->
              let
                nextStep = List.filter (\s -> not s.executed) executableScript.script.steps |> List.head
                cmd = case nextStep of
                    Just c ->
                      let
                        d = Debug.log "Driveby running" ( (toString context.localPort) ++ " " ++ (toString context.browserId) ++ " " ++ c.id ++ ": " ++ c.command.name ++ " " ++ (toString c.command.args) )
                        --rn = Debug.log "RunNextStep" context
                        --m2 = Debug.log "browserIdToScriptId" model.browserIdToScriptId
                        --m3 = Debug.log "scriptIdToExecutableScript" (toString (Dict.keys model.scriptIdToExecutableScript))
                      in
                        ( model, requestsPort (Request c (context)) )
                    --TODO: this is defo wrong, we should'nt have even hit RunNext, should have bailed in Process
                    Nothing ->
                      let
                        executableScript' = { executableScript | finished = Just context.updated }
                        scriptIdToExecutableScript' = Dict.update executableScript.id (\e -> Just executableScript') model.scriptIdToExecutableScript
                        --TODO: this should be in MainLoop
                      in
                        ( { model | scriptIdToExecutableScript = scriptIdToExecutableScript' }, asFx (ScriptFinished ("☑ - "  ++ executableScript.script.name) context))
              in
                 cmd

            Nothing -> (model, Cmd.none)


    Process response ->
        case currentScript response.context model of
            Just executableScript ->
              let
                --rn = Debug.log "Process" response

                --used? debug only?
                currentStep = List.filter (\s -> s.id == response.id) executableScript.script.steps

                -- mark this step as done?
                steps' = List.map (\s -> if s.id == response.id then Step s.id s.command True else s ) executableScript.script.steps
                script = executableScript.script
                script' = { script | steps = steps' }

                executableScript' = { executableScript | script = script'}
                scriptId = response.context.scriptId
                scriptIdToExecutableScript' = Dict.update scriptId (\e -> Just executableScript') model.scriptIdToExecutableScript

                model' = { model | scriptIdToExecutableScript = scriptIdToExecutableScript' }

                --TODO: send ExampleFailure if response has failures
                context = response.context
    --                2011-10-05T14:48:00.000Z
    --                clearlyWrongDate = unsafeFromString "2016-06-17T11:15:00+0200"
                --TOOD: we should really have the stepId ...

                --BUG: if there is an error here we don't run the next step .. so we can't mark the test as finished ...
                --a good argument for doing that check here ...

    --                next = if List.isEmpty response.failures then asFx (RunNext { context | stepId = context.stepId + 1 } )
    --                       else asFx (Exit ("☒ - " ++ executableScript.script.name ++ " " ++ (toString response.failures) ++ " running " ++ (toString current)) response.context)

                next = if List.isEmpty response.failures then Cmd.none
                       else asFx (ScriptFinished ("☒ - " ++ executableScript.script.name ++ " " ++ (toString response.failures) ++ " running " ++ (toString currentStep)) response.context)

                --this looks iffy ...
                --if failed then Exit this test
                --if more steps then RunNextStep
                --if no more steps then RunNextScript
                --if no more scripts then AllDone

              in
                (model', Cmd.batch [ next, asFx (MainLoop response.context) ] )

            Nothing -> (model, Cmd.none)

    --TODO: do we need ScriptFailed, ScriptSucceeded?
    ScriptFinished message context ->
      let
        --TODO: this renders strangely, lets do in js instead ...
        d = Debug.log "Driveby" message

        --TODO: this should be in MainLoop
        scriptsThatNeedToStart= Dict.values model.scriptIdToExecutableScript |> List.filter (\s -> s.started == Nothing )
        scriptsThatNeedToFinish = Dict.values model.scriptIdToExecutableScript |> List.filter (\s -> s.finished == Nothing )

--        d2 = Debug.log "Driveby scriptsThatNeedToStart: " ((toString (List.length scriptsThatNeedToStart)))
--        d3 = Debug.log "Driveby scriptsThatNeedToFinish: " ((toString (List.length scriptsThatNeedToFinish)))

        cmd = if not (List.isEmpty scriptsThatNeedToStart) then asFx (RunNextScript context.browserId context.updated)
              else if not (List.isEmpty scriptsThatNeedToFinish) then Cmd.none
              --TODO: we should be updating the context.stepId whenever we send it through requestsPort or (MainLopp)
              --TODO: we shouldnt have to hardcode this 999 either ..
              --TODO: should be an AllDone me thinks ...
              else (requestsPort (Request (Step "999" close False) (context)))
      in
        ( model, cmd )


currentScript : Context -> Model -> Maybe ExecutableScript
currentScript context model =
  let
    scriptId = Dict.get context.browserId model.browserIdToScriptId
  in
    Dict.get (Maybe.withDefault -1 scriptId) model.scriptIdToExecutableScript


nextUnstartedScript : Model -> Maybe ExecutableScript
nextUnstartedScript model =
  Dict.values model.scriptIdToExecutableScript |> List.filter (\s -> s.started == Nothing ) |> List.head


view : Model -> Html Msg
view model =
  div [ ] [ ]


close : Command
close =
  Command "close" []


asFx : msg -> Cmd msg
asFx msg =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)


--TODO: maybe this can die now we are using JS
runAllScripts : Cmd Msg
runAllScripts =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") RunAllScripts Date.now
