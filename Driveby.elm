--TODO: tighten this up ...
module Driveby exposing (..)
--driveby


import Html.App as App
import Html exposing (..)
import Task
import Date exposing (..)
import Array exposing (..)
import Dict exposing (..)

--TODO: so for sequence its easy, just have a current one and work through the list
--TODO: for parallel, how do we do it?
--TODO: obviously parallel of 1 is same as seq :)
--TODO: ultimately no console sutff in here, report it to js land instead
--TODO: ultimately should take List Script
--when asking for next, just get the next command for the current script, if script is done, get the next script .. etc
--or TEA up the script runners?

--have an Array of executors and put a script in each one ...
--then get and set the script from there ...
--how will we find it again?
--maybe a Dict is better

driveby : Script -> List Script -> (Request -> Cmd Msg) -> ((Response -> Msg) -> Sub Msg) -> Program Flags
driveby script scripts requestsPort responsesPort =
  App.programWithFlags
    { init = init script scripts
    , view = view
    , update = update requestsPort
    , subscriptions = subscriptions responsesPort
    }


--TODO: this stupid N/A Script thing needs to die, maybe it will do when it becomes a list
init : Script -> List Script -> Flags -> (Model, Cmd Msg)
init script scripts flags =
   (Model {-script-} scripts
     (Config flags.browsers)
     Dict.empty
     Dict.empty
     , go)


subscriptions : ((Response -> Msg) -> Sub Msg) -> Model -> Sub Msg
subscriptions responsesPort model =
  responsesPort Process


type alias Flags =
  { browsers : Int }


--TODO: kill script ...
type alias Model =
  { {-script : Script
  ,-}
  scripts : List Script
  , config : Config
  , browserIdToScriptId : Dict Int String
  , scriptIdToScript : Dict String ExecutableScript
  }


--TODO: we may need a bool to say its been run, or maybe store the start, stop times,
--TODO: perhaps make an ExecutableScript that wraps or extends this ...
type alias Script =
  { name : String
  , steps : List Step
  }

type alias ExecutableScript =
  { script: Script
  , id : String
  , started : Maybe String
  , finished : Maybe Date
  }

--TODO: this should poobably be Request and requestId everywhere ...
type alias Step =
  { id : String
  --, scriptId : String
  , command : Command
  , executed : Bool
  }


--TODO: cry to lose/inline Step if we can
--if steps were an array, could it just be the index?
type alias Request =
  { step : Step
  , context : Context
  }


type alias Context =
  { browserId : Int
  , scriptId : String
  , stepId : Int
  , updated : String
  }


--TODO: consider id/selector being a a first class thing, at least a Maybe ...
--TODO: consider value being a a first class thing, at least a Maybe ...
--TODO: consider expected being a a first class thing, at least a Maybe ...
type alias Command =
  { name : String
  , args : List String
  }


--TODO: consider Id as a type and give it the bits it needs ...
--TODO: rename to Result or Outcome
type alias Response =
  { id : String
  , context : Context
  , failures : List String
  }


type alias Config =
  { browsers : Int
  }

--TODO: fix all this naming too
type Msg
  = Go Date
  --TODO: RunScript
  | Start Int String {-Date-}
  --TODO: RunNextCommand
  | RunNext Context
  | Process Response
  | Exit String Context
--TODO: add a Finish (and do the reporting bit here ...)


update : (Request -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
update requestsPort msg model =
  case msg of
    Go theDate ->
      let
        --TODO: store date or lose it ...
        --script' = [model.script] |> List.indexedMap (,) |> List.map(\i s -> {s | id = Just i })
        d = Debug.log "Go" (toString (List.length model.scripts)) ++ (toString theDate)

--        script = model.script
--        script' = { script | id = Just "0" }

        --TODO should be max of browsers and scripts
--        howMany = (model.config.browsers-1)
        howMany = (model.config.browsers)

        --TODO: need to do something better with maybe ...
        --TODO: consider bending them in here .. RunnableScript ...
        scriptIdToScript' = model.scripts |> List.indexedMap (\i s ->
          let
            id = (toString i)
          in
            (id, ExecutableScript s id Nothing Nothing)
        ) |> Dict.fromList

        all = List.repeat howMany 1
              |> List.indexedMap (,)
              |> List.map (\ (i,r) -> (i) )
--              |> List.map (\i -> asFx (Start ({-9000 +-} i (toString theDate))) )
              |> List.map (\i -> asFx (Start i "") )

        x = Cmd.batch (all)

--        dx = Debug.log "x" (toString x)

      in
----      ( { model | script = script' } , asFx (Start 1) )
----        ( { model | script = script', scriptIdToScript = scriptIdToScript' } , x )
        ( { model | scriptIdToScript = scriptIdToScript' } , x )
--        (model, Cmd.none)


    --This isnt really a good name, the intention is to start a script on browserId
    --but actually it runs the next script on this browserid if there is one
    Start browserId theDate ->
      let
        rn = Debug.log "Start" ((toString browserId) ++ (toString theDate))

        --TODO: this needs to be find next avialable Script
--        script = model.script
--          script = Dict.value model.scriptIdToScript

        --THIS IS IT ...
        --find one without a start and update it with one ...
        --then use that id
--        maybeNextScript = Dict.filter (\k v -> v.started == Nothing ) model.scriptIdToScript |> Dict.toList |> List.head
        maybeNextScript = Dict.values model.scriptIdToScript |> List.filter (\s -> s.started == Nothing ) |> List.head

--        d = Debug.log "Start maybeNextScript" maybeNextScript

        (model', cmd) =
          case maybeNextScript of
            Just executableScript ->
              let
                browserIdToScriptId' = Dict.update browserId (\v -> Just executableScript.id) model.browserIdToScriptId
--                browserIdToScriptId' = model.browserIdToScriptId
                context = Context browserId executableScript.id 0 theDate
--                dc = Debug.log "context" context

--                date

--                script = executableScript.script
--                script' = { script | started = Just theDate }

                executableScript' = { executableScript | started = Just theDate }
--                browserId = response.context.browserId
--                browserIdToScriptId' = Dict.update browserId (\v -> script') model.browserIdToScriptId

                scriptId = executableScript.id
                scriptIdToScript' = Dict.update scriptId (\e -> Just executableScript') model.scriptIdToScript

              in
                ( { model | browserIdToScriptId = browserIdToScriptId', scriptIdToScript = scriptIdToScript' } , asFx (RunNext context))
--              (model, Cmd.none)

            Nothing ->
              (model, Cmd.none)


--        running = model.running
--        running' = Array.set browserId script running
--        browserIdToScriptId' = Dict.update browserId (\v -> script.id) model.browserIdToScriptId
        --TODO: kill the maybe ...
--        context = Context browserId "1"

--        d2 = Debug.log "cmd" cmd
--        d3 = Debug.log "new model b2s" model'.browserIdToScriptId
--        d4 = Debug.log "new model s2s" model'.scriptIdToScript

      in
        (model', cmd)
--        ( model , asFx (RunNext browserId))

    RunNext context ->
      let
--        rn = Debug.log "RunNext" context

--        maybeScript = Just model.script
        scriptId = Dict.get context.browserId model.browserIdToScriptId
        maybeScript = Dict.get (Maybe.withDefault "" scriptId) model.scriptIdToScript

--        m2 = Debug.log "browserIdToScriptId" model.browserIdToScriptId
--        m3 = Debug.log "scriptIdToScript" (toString (Dict.keys model.scriptIdToScript))
--        m1 = Debug.log "maybeScript" maybeScript

        cmd2 = case maybeScript of
            Just executableScript ->
              let
                next = List.filter (\s -> not s.executed) executableScript.script.steps |> List.head
                cmd = case next of
                    Just c ->
                      let
                        d = Debug.log "Driveby" ((toString context.browserId) ++ " " ++ c.id ++ ": " ++ c.command.name ++ " " ++ (toString c.command.args) )
--                        m = Debug.log "Model" (toString model.browserIdToScriptId)
        --                m = Debug.log "Model" (toString model.browserIdToScriptId ++ toString model.scriptIdToScript)
                      in
                        requestsPort (Request c (context))
                    --TODO: this looks iffy now ...
                    --TODO: this is defo wrong, we should'nt have even hit RunNext, should have bailed in Process
                    Nothing -> asFx (Exit ("☑ - "  ++ executableScript.script.name) context)
              in
                 cmd

            Nothing -> Cmd.none
      in
        ( model, cmd2 )

    Process response ->
      let
        rn = Debug.log "Process" response

--        maybeScript = Just model.script
        scriptId = Dict.get response.context.browserId model.browserIdToScriptId
        maybeScript = Dict.get (Maybe.withDefault "" scriptId) model.scriptIdToScript

        (model2', next2) = case maybeScript of
            Just executableScript ->
              let
                --used? debug only?
                current = List.filter (\s -> s.id == response.id) executableScript.script.steps

                steps' = List.map (\s -> if s.id == response.id then Step s.id s.command True else s ) executableScript.script.steps
                script = executableScript.script
                script' = { script | steps = steps' }

                executableScript' = { executableScript | script = script'}
--                browserId = response.context.browserId
--                browserIdToScriptId' = Dict.update browserId (\v -> script') model.browserIdToScriptId

                scriptId = response.context.scriptId
                scriptIdToScript' = Dict.update scriptId (\e -> Just executableScript') model.scriptIdToScript
--                scriptIdToScript' = Dict.update scriptId (\e -> e) model.scriptIdToScript

--                model' = { model | script = script', browserIdToScriptId = scriptIdToScript' }
                model' = { model | scriptIdToScript = scriptIdToScript' }

                --TODO: go with Script, Step, Command, Result etc
                --TODO: send ExampleFailure if response has failures
                --TODO: Start should be NextStep
                context = response.context
--                2011-10-05T14:48:00.000Z
--                clearlyWrongDate = unsafeFromString "2016-06-17T11:15:00+0200"
                --TOOD: we should really have the stepId ...
                next = if List.isEmpty response.failures then asFx (RunNext { context | stepId = context.stepId + 1 } )
                       else asFx (Exit ("☒ - " ++ (toString response.failures) ++ " running " ++ (toString current)) response.context)
              in
                (model', next)

            Nothing -> (model, Cmd.none)
      in
        ( model2', next2 )

    --TODO: more like ScriptFinished?
    --TODO: is this Failed really?
    Exit message context ->
      let
        --TODO: this renders odd, lets do in js instead ...
        d = Debug.log "Driveby" message
--        isMoreScripts = Dict.values model.scriptIdToScript |> List.filter (\s -> s.started == Nothing ) |> List.isEmpty
        areAnyUnstarted = Dict.values model.scriptIdToScript |> List.filter (\s -> s.started == Nothing ) |> List.isEmpty
        areAnyStillRunning = Dict.values model.scriptIdToScript |> List.filter (\s -> s.finished == Nothing ) |> List.isEmpty
--        d2 = Debug.log "Driveby isMoreScripts: " ((toString isMoreScripts) ++ (toString (Dict.values model.scriptIdToScript)))
        d2 = Debug.log "Driveby areAnyUnstarted: " ((toString areAnyUnstarted))-- ++ (toString (Dict.values model.scriptIdToScript)))
        d3 = Debug.log "Driveby areAnyStillRunning: " ((toString areAnyStillRunning))-- ++ (toString (Dict.values model.scriptIdToScript)))

        cmd = if areAnyUnstarted
              --TODO: we should be updating the context.stepId whenever we send it through requestsPort
              then (requestsPort (Request (Step "999" close False) (context)))
              else asFx (Start context.browserId context.updated)

--              then Cmd.none
--              else Cmd.none
      in
        --TODO: this 1 is well dodgy ...
        --TODO: and this "1" we need to pass in a context really
        --TODO: the less said about the last one the better
        ( model, cmd )


view : Model -> Html Msg
view model =
  div [ ] [ ]


asFx : msg -> Cmd msg
asFx msg =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)


go : Cmd Msg
go =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") Go Date.now

---

unsafeFromString : String -> Date
unsafeFromString dateStr =
  case Date.fromString dateStr of
    Ok date -> date
    Err msg -> Debug.crash("unsafeFromString")


---

script : String -> List Command -> Script
script name commands =
  Script name (commands
      |> List.indexedMap (,)
      |> List.map (\(i,r) -> Step (toString i) r False))


--TODO: eventually these will be in Driveby.Command or something
serve : String -> Int -> Command
serve path onPort =
  Command "serve" [path, toString onPort]


goto : String -> Command
goto url =
  Command "goto" [url]


click : String -> Command
click id =
  Command "click" ["#" ++ id]


enter : String -> String -> Command
enter id value =
  Command "enter" ["#" ++ id, value]


close : Command
close =
  Command "close" []
