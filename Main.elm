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


--TODO: server - add port, will make it better for paralle
--TODO: goto - url should be "/elm.html"
--TODO: textContains needs to have the expected
--TODO: close should not take any args
--TODO: should args just be a list?
commands : List Step
commands =
    [ Request "serve" "../shoreditch-ui-chrome/chrome" Nothing
    , Request "goto" "url" Nothing
    , Request "click" "#refreshButton" Nothing
    , Request "textContains" "#messageList" (Just "ManualMetaDataRefresh")
    , Request "close" "" Nothing
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
  , arg: String
  , expected: Maybe String
  }


type alias Response =
  { id: String
  , failures: List String
  }


type Msg
  = Start
  | Suggest Response
  | Exit String


{-| blah
-}
port check : Step -> Cmd msg


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Start ->
      let
        next = List.filter (\s -> not s.executed) model.commands |> List.head
        cmd = case next of
            Just c -> check c
            Nothing -> Cmd.none
        d = Debug.log "> elm sending next: " next
      in
      ( model, cmd)

    Suggest response ->
      let
        d = Debug.log "> elm received response: " response
        steps' = List.map (\s -> if s.id == response.id then Step s.id s.request True else s ) model.commands
        model' = { model | commands = steps' }
        --TODO: send ExampleFailure if response has failures
        --TODO: Start should be NextStep
        next = if List.isEmpty response.failures then asFx Start else asFx (Exit "Spec Failed")
      in
      ( model', next )

    Exit message ->
      ( model, check (Step "999" (Request "close" "" Nothing) False) )


port suggestions : (Response -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  suggestions Suggest


view : Model -> Html Msg
view model =
  div [ ] [ ]


asFx : msg -> Cmd msg
asFx msg =
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)
