--TODO: tighten this up ... expose minimum (driveby)
module Driveby exposing (..)


import Html.App as App
import Html exposing (..)
import Task
import Date exposing (..)
import Array exposing (..)
import Dict exposing (..)

--TODO: ultimately no console sutff in here, report it to js land instead
--when asking for next, just get the next command for the current script, if script is done, get the next script .. etc
--or TEA up the script runners?


driveby : List Script -> (Request -> Cmd Msg) -> ((Response -> Msg) -> Sub Msg) -> Program Flags
driveby scripts requestsPort responsesPort =
  App.programWithFlags
    { init = init scripts
    , view = view
    , update = update requestsPort
    , subscriptions = subscriptions responsesPort
    }


init : List Script -> Flags -> (Model, Cmd Msg)
init scripts flags =
   (Model scripts (Config flags.browsers) Dict.empty Dict.empty, go)


subscriptions : ((Response -> Msg) -> Sub Msg) -> Model -> Sub Msg
subscriptions responsesPort model =
  responsesPort Process


type alias Flags =
  { browsers : Int }


-- TODO: ultimately scripts arent needed, they become scriptIdToScript
-- TODO: ultimately config isnt needed, they become browserIdToScriptId (mainly)
type alias Model =
  { scripts : List Script
  , config : Config
  , browserIdToScriptId : Dict Int String
  , scriptIdToScript : Dict String ExecutableScript
  }


type alias Script =
  { name : String
  , steps : List Step
  }


type alias ExecutableScript =
  { script: Script
  , id : String
  , started : Maybe String {-Date-}
  , finished : Maybe String {-Date-}
  }


--TODO: this should probably be Request and requestId everywhere ...
--TODO: can this id die, I'm not sure yet ...
type alias Step =
  { id : String
  , command : Command
  , executed : Bool
  }


--TODO: try to lose/inline Step if we can
--if steps were an array, could it just be the index? or recipe for equality issues?
type alias Request =
  { step : Step
  , context : Context
  }


type alias Context =
  { localPort : Int
  , browserId : Int
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
        d = Debug.log "Go " ((toString (List.length model.scripts) ++ (toString theDate) ++ (toString model.config)))

        numberOfBrowsersToUse = model.config.browsers

        scriptIdToScript' = model.scripts |> List.indexedMap (\i s ->
          let
            id = (toString i)
          in
            (id, ExecutableScript s id Nothing Nothing)
        ) |> Dict.fromList

        all = List.repeat numberOfBrowsersToUse 1
              |> List.indexedMap (,)
              |> List.map (\ (i,r) -> (i) )
              |> List.map (\i -> asFx (Start i "") )

        x = Cmd.batch (all)

      in
        ( { model | scriptIdToScript = scriptIdToScript' } , x )


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

    RunNext context ->
      let
--        rn = Debug.log "RunNext" context

        scriptId = Dict.get context.browserId model.browserIdToScriptId
        maybeScript = Dict.get (Maybe.withDefault "" scriptId) model.scriptIdToScript

--        m2 = Debug.log "browserIdToScriptId" model.browserIdToScriptId
--        m3 = Debug.log "scriptIdToScript" (toString (Dict.keys model.scriptIdToScript))

        (model2, cmd2) = case maybeScript of
            Just executableScript ->
              let
                next = List.filter (\s -> not s.executed) executableScript.script.steps |> List.head
                cmd = case next of
                    Just c ->
                      let
                        d = Debug.log "Driveby" ( (toString context.localPort) ++ " " ++ (toString context.browserId) ++ " " ++ c.id ++ ": " ++ c.command.name ++ " " ++ (toString c.command.args) )
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

                next = if List.isEmpty response.failures then asFx (RunNext { context | stepId = context.stepId + 1 } )
                       else asFx (Exit ("☒ - " ++ executableScript.script.name ++ " " ++ (toString response.failures) ++ " running " ++ (toString current)) response.context)
              in
                (model', next)

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


view : Model -> Html Msg
view model =
  div [ ] [ ]


asFx : msg -> Cmd msg
asFx msg =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)


--TODO: this can probably die now we are using JS
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
  Script name (
    ( List.append [ Command "init" [] ] commands)
      |> List.indexedMap (,)
      |> List.map (\(i,r) -> Step (toString i) r False))


--TODO: pull out all the other stuff to a runner or engine ...
--TODO: eventually these will be in Driveby.Command or something
serve : String -> Command
serve path =
  Command "serve" [path]


stub : String -> String -> Command
stub path content =
  Command "stub" [path, content]


goto : String -> Command
goto url =
  Command "goto" [url]


gotoLocal : String -> Command
gotoLocal path =
  Command "gotoLocal" [path]


click : String -> Command
click id =
  Command "click" ["#" ++ id]


enter : String -> String -> Command
enter id value =
  Command "enter" ["#" ++ id, value]


close : Command
close =
  Command "close" []
