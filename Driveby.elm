--TODO: tighten this up ...
module Driveby exposing (..)
--main


import Html.App as App
import Html exposing (..)
import Task


driveby tests subscriptions checker =
  App.program
    { init = (Model tests, asFx Start )
    , view = view
    , update = update checker
    , subscriptions = subscriptions
    }


type alias Step =
  { id: String
  , request: Request
  , executed: Bool
  }


--TODO: make command: Command
type alias Request =
  { command: String
  , args: List String
  }


--TODO: consider Id as a type and give it the bits it needs ...
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


--TODO: this will be the driveby update ...
--TODO: we will probably need our own to handle DriveBy.Msg ... like the DatePicker ...
--update : Msg -> Model -> (Model, Cmd Msg)
update checker msg model =
  case msg of
    Start ->
      let
        next = List.filter (\s -> not s.executed) model.commands |> List.head
        cmd = case next of
            Just c ->
              let d = Debug.log "Driveby" (c.request.command ++ " " ++ (toString c.request.args) )
              in checker c --check
            Nothing -> asFx (Exit ("Passed") )
      in
      ( model, cmd )

    Suggest response ->
      let
        current = List.filter (\s -> s.id == response.id) model.commands
        steps' = List.map (\s -> if s.id == response.id then Step s.id s.request True else s ) model.commands
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
      ( model, checker (Step "999" (Request "close" [] ) False) {-check-} )


view : Model -> Html Msg
view model =
  div [ ] [ ]


asFx : msg -> Cmd msg
asFx msg =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)
