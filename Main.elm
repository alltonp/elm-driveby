port module DrivebyTest exposing (check)
--command?
--result?

import Driveby exposing (..)


main =
   driveby commands update subscriptions checker


--TODO: specify this using functions, to ensure the correct args ... click id etc
--TODO: ensure the Script top level has a description ..
--TODO: should be assert [ "textContains", "#messageList", "Auto Loading Metadata" ]
--TODO: or assert [ "#messageList" "textContains", "Auto Loading Metadata" ]
--TODO: might map well to jquery functions
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


--TODO: need to be exposed somehow
port check : Step -> Cmd msg

--check : Msg -> (Step -> Cmd msg)
checker m p =
    p m

--TODO: this will be the drivby update ...
--TODO: we will probably need our own to handle DriveBy.Msg ... like the DatePicker ...
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Start ->
      let
        next = List.filter (\s -> not s.executed) model.commands |> List.head
        cmd = case next of
            Just c ->
              let d = Debug.log "Driveby" (c.request.command ++ " " ++ (toString c.request.args) )
              in checker c check
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
      ( model, checker (Step "999" (Request "close" [] ) False) check )


--TODO: need to be exposed somehow
port suggestions : (Response -> msg) -> Sub msg


--TODO: need to be exposed somehow
subscriptions : Model -> Sub Msg
subscriptions model =
  suggestions Suggest

