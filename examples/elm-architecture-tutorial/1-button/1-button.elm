--TIP: https://github.com/evancz/elm-architecture-tutorial/blob/master/examples/1-button.elm
import Html exposing (Html, button, div, text)
import Html.App as Html
import Html.Events exposing (onClick)
import Html.Attributes exposing (id)


main =
  Html.beginnerProgram
    { model = model
    , view = view
    , update = update
    }



-- MODEL


type alias Model = Int


model : Model
model =
  0



-- UPDATE


type Msg
  = Increment
  | Decrement


update : Msg -> Model -> Model
update msg model =
  case msg of
    Increment ->
      model + 1

    Decrement ->
      model - 1



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ button [ id "decrement", onClick Decrement ] [ text "-" ]
    , div [ id "count" ] [ text (toString model) ]
    , button [ id "increment", onClick Increment ] [ text "+" ]
    ]
