port module Spelling exposing (check)


{-|  Wibbly
  e.g.
  @docs check
-}


import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import String
import Task


main =
  App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


--TODO: make script: List Command
type alias Model =
  { commands : List Step
  }

init : (Model, Cmd Msg)
init =
  (Model commands, asFx Start )


--TODO: specify this using functions, to ensure the correct args ... click id etc
--TODO: ensure the Script top level has a description ..
--TODO: should be assert [ "textContains" etc ... ]
commands : List Step
commands =
    [ Request "serve" [ "../shoreditch-ui-chrome/chrome", "8080" ]
    , Request "goto" [ "http://localhost:8080/elm.html" ]
    , Request "textContains" [ "#messageList", "Auto Loading Metadata" ]
    , Request "click" [ "#refreshButton" ]
    , Request "textContains" [ "#messageList", "ManualMetaDataRefresh" ]
    ]
    |> List.indexedMap (,)
    |> List.map (\(i,r) -> Step (toString i) r False)


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


{-| blah
-}
--TODO: need to be exposed somehow
port check : Step -> Cmd msg


--TODO: this will be the drivby update ...
--TODO: we will probably need our own to handle DriveBy.Msg ... like the DatePicker ...
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Start ->
      let
        next = List.filter (\s -> not s.executed) model.commands |> List.head
        cmd = case next of
            Just c -> check c
            Nothing -> asFx (Exit ("Spec Passed") )
        --d = Debug.log "> elm sending next: " next
      in
      ( model, cmd)

    Suggest response ->
      let
        current = List.filter (\s -> s.id == response.id) model.commands
        steps' = List.map (\s -> if s.id == response.id then Step s.id s.request True else s ) model.commands
        model' = { model | commands = steps' }
        --TODO: go with Script, Step, Command, Result etc
        --TODO: send ExampleFailure if response has failures
        --TODO: Start should be NextStep
        next = if List.isEmpty response.failures then asFx Start
               else asFx (Exit ("Spec Failed: " ++ (toString response.failures) ++ " running " ++ (toString current)) )
      in
      ( model', next )

    --TODO: is this Failed really?
    Exit message ->
      let
        --TODO: this is odd, lets do in js instead ...
        d = Debug.log ("Driveby: " ++ message) ""
      in
      ( model, check (Step "999" (Request "close" [] ) False) )


--TODO: need to be exposed somehow
port suggestions : (Response -> msg) -> Sub msg

--TODO: need to be exposed somehow
subscriptions : Model -> Sub Msg
subscriptions model =
  suggestions Suggest


view : Model -> Html Msg
view model =
  div [ ] [ ]


asFx : msg -> Cmd msg
asFx msg =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)
