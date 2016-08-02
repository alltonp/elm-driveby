--TODO: tighten this up ...
module Driveby exposing (..)
--driveby


import Html.App as App
import Html exposing (..)
import Task
import Date exposing (..)


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


init : Script -> Flags -> (Model, Cmd Msg)
init script flags =
   (Model script (Config flags.browsers), go)


subscriptions : ((Response -> Msg) -> Sub Msg) -> Model -> Sub Msg
subscriptions responsesPort model =
  responsesPort Process


type alias Flags =
  { browsers : Int }


--TODO: so we want a list of scripts, and ultimately run them in parallel, but for now in sequence
type alias Model =
  { script : Script
  , config : Config
  }


--TODO: we may need a bool to say its been run, or maybe store the start, stop times,
type alias Script =
  { name: String
  , steps: List Step
  , id: Maybe String
  }


--TODO: this should poobably be Request and requestId everywhere ...
type alias Step =
  { id: String
  --, scriptId : String
  , command: Command
  , executed: Bool
  }


--TODO: cry to lose/inline Step if we can
--if steps were an array, could it just be the index?
type alias Request =
  { step: Step
  , context: Context
  }


type alias Context =
  { browser: Int
  }


--TODO: consider id/selector being a a first class thing, at least a Maybe ...
--TODO: consider value being a a first class thing, at least a Maybe ...
--TODO: consider expected being a a first class thing, at least a Maybe ...
type alias Command =
  { name: String
  , args: List String
  }


--TODO: consider Id as a type and give it the bits it needs ...
--TODO: rename to Result or Outcome
type alias Response =
  { id: String
  , context: Context
  , failures: List String
  }


type alias Config =
  { browsers: Int
  }

--TODO: fix all this naming too
type Msg
  = Go Date
  | Start Int
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
        d = Debug.log "Configuring" (toString model)

        script = model.script
        script' = { script | id = Just "1" }
        --model.config.browsers
      in
      ( { model | script = script' } , asFx (Start 1) )

    Start browser ->
      let
        next = List.filter (\s -> not s.executed) model.script.steps |> List.head
        cmd = case next of
            Just c ->
--              let
--                d = Debug.log "Driveby" (c.id ++ ": " ++ c.command.name ++ " " ++ (toString c.command.args) )
--              in
                requestsPort (Request c (Context browser))
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
        next = if List.isEmpty response.failures then asFx (Start 1 {-response.browser-})
               else asFx (Exit ("☒ - " ++ (toString response.failures) ++ " running " ++ (toString current)) )
      in
      ( model', next )

    --TODO: is this Failed really?
    Exit message ->
      let
        --TODO: this is odd, lets do in js instead ...
        d = Debug.log "Driveby" message
      in
      ( model, requestsPort (Request (Step "999" close False) (Context 1)) )


view : Model -> Html Msg
view model =
  div [ ] [ ]


asFx : msg -> Cmd msg
asFx msg =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)


go : Cmd Msg
go = Task.perform (\_ -> Debug.crash "This failure cannot happen.") Go Date.now

---

script : String -> List Command -> Script
script name commands =
  Script name (commands
      |> List.indexedMap (,)
      |> List.map (\(i,r) -> Step (toString i) r False)) Nothing


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
