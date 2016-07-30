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
    [ Request "goto" "url"
    , Request "click" "#refreshButton"
    , Request "textContains" "#messageList"
    , Request "close" ""
    ]
    |> List.indexedMap (,)
    |> List.map (\(i,r) -> Step (toString i) r False)

-- UPDATE

type alias Step =
  { id: String
  , request: Request
  , executed: Bool
  }


--TODO: make command: Command
type alias Request =
  { command: String
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
        steps' = List.map (\s -> if s.id == response.id then Step s.id s.request True else s ) model.commands
        model' = { model | commands = steps' }
        --TODO: send ExampleFailure if response has failures
        --TODO: Start should be NextStep
      in
      ( model', asFx Start )


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
