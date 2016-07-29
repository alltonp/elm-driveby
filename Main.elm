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


-- MODEL

type alias Model =
  { word : String
  , suggestions : List String
  }

init : (Model, Cmd Msg)
init =
  (Model "z" [], asFx Start )


-- UPDATE

type alias Request =
  { id: String
  , command: String
  }

type alias Response =
  { id: String
  , failures: List String
  }


type Msg
  = Start
  | Change String
  | Check
  | Suggest Response


{-| blah
-}
port check : Request -> Cmd msg

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Start ->
      let
        d = Debug.log "elm sent" model.word
      in ( model, check (Request "" model.word) )

    Change newWord ->
      ( Model newWord [], Cmd.none )

    Check ->
      let
        d = Debug.log "elm sent" model.word
      in ( model, check (Request "" model.word) )

    Suggest newSuggestions ->
      let
        d = Debug.log "elm received" newSuggestions
      in
      ( Model model.word newSuggestions.failures, Cmd.none )


-- SUBSCRIPTIONS

port suggestions : (Response -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  suggestions Suggest


-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ input [ onInput Change ] []
    , button [ onClick Check ] [ text "Check" ]
    , div [] [ text (String.join ", " model.suggestions) ]
    ]


---

asFx : msg -> Cmd msg
asFx msg =
  --Task.Extra.performFailproof identity |> msg
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)
