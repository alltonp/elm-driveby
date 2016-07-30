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

--TODO: make script: List Command
type alias Model =
  { word : String
  , suggestions : List String
  , commands : List Step
  }

init : (Model, Cmd Msg)
init =
  (Model "z" [] commands, asFx Start )


commands : List Step
commands =
    [ Request "1" "goto" "url"
    , Request "1" "click" "#refreshButton"
    ] |> List.map (\r -> Step r False)

-- UPDATE

type alias Step =
  { request: Request
  , executed: Bool
  }


--TODO: make command: Command
type alias Request =
  { id: String
  , command: String
  , arg: String
  }


type alias Response =
  { id: String
  , failures: List String
  }


type Msg
  = Start
--  | Change String
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
        next = List.head model.commands
        cmd = case next of
            Just c -> check c.request
            Nothing -> Cmd.none
        d = Debug.log "elm sending" (toString cmd)
      in
--      ( model, check (Request "1" "click" "#refreshButton") )
      ( model, cmd)

--    Change newWord ->
--      ( Model newWord [], Cmd.none )

    Check ->
--      let
--        d = Debug.log "elm sent" model.word
--      in
      ( model, Cmd.none )

    Suggest response ->
      let
        d = Debug.log "> elm received" response
      in
      ( model, Cmd.none )


-- SUBSCRIPTIONS

port suggestions : (Response -> msg) -> Sub msg

subscriptions : Model -> Sub Msg
subscriptions model =
  suggestions Suggest


-- VIEW

view : Model -> Html Msg
view model =
  div []
    [
--    input [ onInput Change ] []
--    ,
    button [ onClick Check ] [ text "Check" ]
    , div [] [ text (String.join ", " model.suggestions) ]
    ]


---

asFx : msg -> Cmd msg
asFx msg =
  --Task.Extra.performFailproof identity |> msg
  Task.perform (\_ -> Debug.crash "This failure cannot happen.") identity (Task.succeed msg)
