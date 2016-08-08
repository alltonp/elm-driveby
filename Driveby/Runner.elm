module Driveby.Runner exposing (Msg, Flags, init, update, view, subscriptions)


import Driveby.Model exposing (..)
import Date exposing (..)
import Task
import Dict exposing (..)
import Html exposing (..)


init : List Script -> Flags -> (Model, Cmd Msg)
init scripts flags =
   (Model scripts (Config flags.browsers) Dict.empty Dict.empty, go)


subscriptions : ((Response -> Msg) -> Sub Msg) -> Model -> Sub Msg
subscriptions responsesPort model =
  responsesPort Process


type alias Flags =
  { browsers : Int }


type alias Config =
  { browsers : Int }


-- TODO: ultimately scripts arent needed, they become scriptIdToScript
-- TODO: ultimately config isnt needed, they become browserIdToScriptId (mainly)
type alias Model =
  { scripts : List Script
  , config : Config
  , browserIdToScriptId : Dict Int Int
  --TODO: toExecutableScript
  , scriptIdToScript : Dict Int ExecutableScript
  }


type alias ExecutableScript =
  { script: Script
  , id : Int
  , started : Maybe String {-Date-}
  , finished : Maybe String {-Date-}
  }


--TODO: fix all this naming too
type Msg
  -- TODO: RunAllScripts
  = Go Date
  --TODO: RunNextScript?
  | Start Int String {-Date-}
  --TODO: RunNextCommand
  | RunNext Context
  | Process Response
  | MainLoop Context
  --TODO: though it was StepFailed ... but no it's ScriptFinished ...
  | Exit String Context

--TODO: add a Finish/AllDone (and do the reporting bit here ...)


update : (Request -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
update requestsPort msg model =
  case msg of
    --TODO: store date or lose it ...
    Go theDate ->
      let
        d = Debug.log "Go " ((toString (List.length model.scripts) ++ (toString theDate) ++ (toString model.config)))

        numberOfBrowsersToUse = model.config.browsers

        scriptIdToScript' = model.scripts |> List.indexedMap (\i s ->
          let
            scriptId = i
          in
            (scriptId, ExecutableScript s scriptId Nothing Nothing)
        ) |> Dict.fromList

        all = List.repeat numberOfBrowsersToUse 1
              |> List.indexedMap (,)
              |> List.map (\ (i,r) -> (i) )
              |> List.map (\i -> asFx (Start i "") )
      in
        ( { model | scriptIdToScript = scriptIdToScript' } , Cmd.batch (all) )


    --This isnt really a good name, the intention is to start a script on browserId
    --but actually it runs the next script on this browserid if there is one
    -- fix the implementation ...
    -- might not need the date anymore
    Start browserId theDate ->
      let
        maybeNextScript = Dict.values model.scriptIdToScript |> List.filter (\s -> s.started == Nothing ) |> List.head

        (model', cmd) =
          case maybeNextScript of
            Just executableScript ->
              let
--                rn = Debug.log "Start script on browser: " ((toString executableScript.id) ++  " " ++ (toString browserId) ++ (toString theDate))

                browserIdToScriptId' = Dict.update browserId (\v -> Just executableScript.id) model.browserIdToScriptId
                context = Context -1 browserId executableScript.id 0 theDate

                executableScript' = { executableScript | started = Just theDate }
                scriptId = executableScript.id
                scriptIdToScript' = Dict.update scriptId (\e -> Just executableScript') model.scriptIdToScript

              in
                ( { model | browserIdToScriptId = browserIdToScriptId', scriptIdToScript = scriptIdToScript' } , asFx (RunNext context))

            Nothing ->
              (model, Cmd.none)

      in
        (model', cmd)


    MainLoop context ->
      let
        d = Debug.log "MainLoop" (toString context)

        nextCmd = asFx (RunNext { context | stepId = context.stepId + 1 } )
      in
        (model, nextCmd)


    RunNext context ->
      let
--        rn = Debug.log "RunNext" context
--        m2 = Debug.log "browserIdToScriptId" model.browserIdToScriptId
--        m3 = Debug.log "scriptIdToScript" (toString (Dict.keys model.scriptIdToScript))

        (model2, cmd2) = case currentScript context model of
            Just executableScript ->
              let
                nextStep = List.filter (\s -> not s.executed) executableScript.script.steps |> List.head
                cmd = case nextStep of
                    Just c ->
                      let
                        d = Debug.log "Driveby running" ( (toString context.localPort) ++ " " ++ (toString context.browserId) ++ " " ++ c.id ++ ": " ++ c.command.name ++ " " ++ (toString c.command.args) )
                      in
                        ( model, requestsPort (Request c (context))
                        )
                    --TODO: this is defo wrong, we should'nt have even hit RunNext, should have bailed in Process
                    Nothing ->
                      let
                        executableScript' = { executableScript | finished = Just context.updated }
                        scriptIdToScript' = Dict.update executableScript.id (\e -> Just executableScript') model.scriptIdToScript

                      in
                        ( { model | scriptIdToScript = scriptIdToScript' }, asFx (Exit ("☑ - "  ++ executableScript.script.name) context))
              in
                 cmd

            Nothing -> (model, Cmd.none)
      in
        ( model2, cmd2 )


    Process response ->
      let
--        rn = Debug.log "Process" response

        (model2', next2) = case currentScript response.context model of
            Just executableScript ->
              let
                --used? debug only?
                currentStep = List.filter (\s -> s.id == response.id) executableScript.script.steps

                steps' = List.map (\s -> if s.id == response.id then Step s.id s.command True else s ) executableScript.script.steps
                script = executableScript.script
                script' = { script | steps = steps' }

                executableScript' = { executableScript | script = script'}
                scriptId = response.context.scriptId
                scriptIdToScript' = Dict.update scriptId (\e -> Just executableScript') model.scriptIdToScript
                model' = { model | scriptIdToScript = scriptIdToScript' }

                --TODO: go with Script, Step, Command, Result etc
                --TODO: send ExampleFailure if response has failures
                --TODO: Start should be NextStep
                context = response.context
--                2011-10-05T14:48:00.000Z
--                clearlyWrongDate = unsafeFromString "2016-06-17T11:15:00+0200"
                --TOOD: we should really have the stepId ...

                --BUG: if there is an error here we don't run the next step .. so we can't mark the test as finished ...
                --a good argument for doing that check here ...

--                next = if List.isEmpty response.failures then asFx (RunNext { context | stepId = context.stepId + 1 } )
--                       else asFx (Exit ("☒ - " ++ executableScript.script.name ++ " " ++ (toString response.failures) ++ " running " ++ (toString current)) response.context)

                next = if List.isEmpty response.failures then Cmd.none
                       else asFx (Exit ("☒ - " ++ executableScript.script.name ++ " " ++ (toString response.failures) ++ " running " ++ (toString currentStep)) response.context)

                --this looks iffy ...
                --if failed then Exit this test
                --if more steps then RunNextStep
                --if no more steps then RunNextScript
                --if no more scripts then AllDone

              in
                (model', Cmd.batch [ next, asFx (MainLoop response.context) ] )

            Nothing -> (model, Cmd.none)
      in
        ( model2', next2 )

    --TODO: this looks like ScriptFinished?
    Exit message context ->
      let
        --TODO: this renders strangely, lets do in js instead ...
        d = Debug.log "Driveby" message

        needStarting = Dict.values model.scriptIdToScript |> List.filter (\s -> s.started == Nothing )
        needFinishing = Dict.values model.scriptIdToScript |> List.filter (\s -> s.finished == Nothing )

--        d2 = Debug.log "Driveby needStarting: " ((toString (List.length needStarting)))
--        d3 = Debug.log "Driveby needFinishing: " ((toString (List.length needFinishing)))

        cmd = if not (List.isEmpty needStarting) then asFx (Start context.browserId context.updated)
              else if not (List.isEmpty needFinishing) then Cmd.none
              --TODO: we should be updating the context.stepId whenever we send it through requestsPort
              --TODO: we shouldnt have to hardcode this 999 either ..
              else (requestsPort (Request (Step "999" close False) (context)))
      in
        ( model, cmd )


currentScript : Context -> Model -> Maybe ExecutableScript
currentScript context model =
  let
    scriptId = Dict.get context.browserId model.browserIdToScriptId
    maybeScript = Dict.get (Maybe.withDefault -1 scriptId) model.scriptIdToScript
  in
    maybeScript


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
go : Cmd Msg
go =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") Go Date.now

