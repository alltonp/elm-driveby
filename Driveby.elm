--TODO: tighten this up ...
module Driveby exposing (..)
--driveby


import Html.App as App
import Html exposing (..)
import Task


--TODO: ultimately no console sutff in here, report it to js land instead
--TODO: ultimately should take List Script
driveby : Script -> (Step -> Cmd Msg) -> ((Response -> Msg) -> Sub Msg) -> Program Never
driveby script commandsPort resultsPort =
  App.program
    { init = (Model script.steps, asFx Start)
    , view = view
    , update = update commandsPort
    , subscriptions = subscriptions resultsPort
    }


subscriptions : ((Response -> Msg) -> Sub Msg) -> Model -> Sub Msg
subscriptions results model =
  results Suggest


--TODO: we may need a bool to say its been run, or maybe store the start, stop times,
type alias Script =
  { name: String
  , steps: List Step
  }


type alias Step =
  { id: String
  , command: Command
  , executed: Bool
  }


type alias Command =
  { name: String
  , args: List String
  }


--TODO: consider Id as a type and give it the bits it needs ...
--TODO: rename to Result
type alias Response =
  { id: String
  , failures: List String
  }


--TODO: fix all this naming too
type Msg
  = Start
  | Suggest Response
  | Exit String
--TODO: add a Finish (and do the reporting bit here ...)


--TODO: make script: List Command
type alias Model =
  { commands : List Step
  }


update : (Step -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
update commandsPort msg model =
  case msg of
    Start ->
      let
        next = List.filter (\s -> not s.executed) model.commands |> List.head
        cmd = case next of
            Just c ->
              let d = Debug.log "Driveby" (c.command.name ++ " " ++ (toString c.command.args) )
              in commandsPort c
            Nothing -> asFx (Exit ("Passed") )
      in
      ( model, cmd )

    Suggest response ->
      let
        current = List.filter (\s -> s.id == response.id) model.commands
        steps' = List.map (\s -> if s.id == response.id then Step s.id s.command True else s ) model.commands
        model' = { model | commands = steps' }
        --TODO: go with Script, Step, Command, Result etc
        --TODO: send ExampleFailure if response has failures
        --TODO: Start should be NextStep
        next = if List.isEmpty response.failures then asFx Start
               else asFx (Exit ("Failed: " ++ (toString response.failures) ++ " running " ++ (toString current)) )
      in
      ( model', next )

    --TODO: is this Failed really?
    Exit message ->
      let
        --TODO: this is odd, lets do in js instead ...
        d = Debug.log "Driveby" message
      in
      ( model, commandsPort (Step "999" (Command "close" [] ) False) {-check-} )


view : Model -> Html Msg
view model =
  div [ ] [ ]


asFx : msg -> Cmd msg
asFx msg =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)


---

script : String -> List Command -> Script
script name steps =
  Script name (steps
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