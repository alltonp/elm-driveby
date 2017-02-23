--TIP: https://github.com/evancz/elm-architecture-tutorial/blob/master/examples/2-field.elm


module Main exposing (..)

import Html exposing (Html, Attribute, div, input, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Html.Attributes exposing (id)
import String


main =
    Html.beginnerProgram
        { model = model
        , view = view
        , update = update
        }



-- MODEL


type alias Model =
    { content : String
    }


model : Model
model =
    Model ""



-- UPDATE


type Msg
    = Change String


update : Msg -> Model -> Model
update msg model =
    case msg of
        Change newContent ->
            { model | content = newContent }



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ input [ id "text", placeholder "Text to reverse", onInput Change ] []
        , div [ id "reversed" ] [ text (String.reverse model.content) ]
        ]
