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

driveby : Script -> (Request -> Cmd Msg) -> ((Response -> Msg) -> Sub Msg) -> Program Flags
driveby script requestsPort responsesPort =
  App.programWithFlags
    { init = init script
    , view = view
    , update = update requestsPort
    , subscriptions = subscriptions responsesPort
    }


--TODO: this stupid N/A Script thing needs to die, maybe it will do when it becomes a list
init : Script -> Flags -> (Model, Cmd Msg)
init script flags =
   (Model script
     (Config flags.browsers)
--     (Array.repeat flags.browsers (Script "N/A" [] Nothing Nothing Nothing) )
     (Dict.fromList [("0", Just "0")])
     , go)


subscriptions : ((Response -> Msg) -> Sub Msg) -> Model -> Sub Msg
subscriptions responsesPort model =
  responsesPort Process


type alias Flags =
  { browsers : Int }


--TODO: so we want a list of scripts, and ultimately run them in parallel, but for now in sequence
type alias Model =
  { script : Script
  , config : Config
  --TODO: I think this needs to die
--  , running : Array Script
  , browserIdToScriptId : Dict String (Maybe String)
  }


--TODO: we may need a bool to say its been run, or maybe store the start, stop times,
--TODO: perhaps make an ExecutableScript that wraps or extends this ...
type alias Script =
  { name : String
  , steps : List Step
  --TODO: make me not a Maybe ideally ..
  , id : Maybe String
  , started : Maybe Date
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
  | Start Int
  | RunNext Int
--  | Setup Config
  | Process Response
  | Exit String
--TODO: add a Finish (and do the reporting bit here ...)


update : (Request -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
update requestsPort msg model =
  case msg of
    Go date ->
      let
        --TODO: store date or lose it ...
        --script' = [model.script] |> List.indexedMap (,) |> List.map(\i s -> {s | id = Just i })
--        d = Debug.log "Configuring" (toString model)

        script = model.script
        script' = { script | id = Just "1" }

        --TODO should be max of browsers and scripts
        howMany = (model.config.browsers-1)

--        browserIdToScriptId' = List.repeat howMany (Nothing) |> List.indexedMap (\i a -> (toString i, a)) |> Dict.fromList

        all = List.repeat howMany 0
              |> List.indexedMap (,)
              |> List.map (\(i,r) -> asFx (Start i) )

        x = Cmd.batch (all)

--        dx = Debug.log "x" (toString x)

      in
--      ( { model | script = script' } , asFx (Start 1) )
        ( { model | script = script' } , x )

    Start browserId ->
      let
        script = model.script
--        running = model.running
--        running' = Array.set browserId script running
      in
--        ( { model | running = running' } , asFx (RunNext browserId))
        ( model , asFx (RunNext browserId))

    RunNext browserId ->
      let
        next = List.filter (\s -> not s.executed) model.script.steps |> List.head
        cmd = case next of
            Just c ->
              let
                d = Debug.log "Driveby" ((toString browserId) ++ " " ++ c.id ++ ": " ++ c.command.name ++ " " ++ (toString c.command.args) )
              in
                requestsPort (Request c (Context browserId))
            --TODO: this looks iffy now ...
            Nothing -> asFx (Exit ("☑ - "  ++ model.script.name) )
      in
        ( model, cmd )

    Process response ->
      let
        script = model.script
        current = List.filter (\s -> s.id == response.id) script.steps
        steps' = List.map (\s -> if s.id == response.id then Step s.id s.command True else s ) script.steps
        script' = { script | steps = steps' }
        model' = { model | script = script' }
        --TODO: go with Script, Step, Command, Result etc
        --TODO: send ExampleFailure if response has failures
        --TODO: Start should be NextStep
        next = if List.isEmpty response.failures then asFx (RunNext response.context.browserId)
               else asFx (Exit ("☒ - " ++ (toString response.failures) ++ " running " ++ (toString current)) )
      in
        ( model', next )

    --TODO: is this Failed really?
    Exit message ->
      let
        --TODO: this renders odd, lets do in js instead ...
        d = Debug.log "Driveby" message
      in
        --TODO: this 1 is well dodgy ...
        ( model, requestsPort (Request (Step "999" close False) (Context 1)) )


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

script : String -> List Command -> Script
script name commands =
  Script name (commands
      |> List.indexedMap (,)
      |> List.map (\(i,r) -> Step (toString i) r False)) Nothing Nothing Nothing


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
