port module DrivebyTest exposing (check)
--command?
--result?

import Driveby exposing (..)


main =
   driveby commands subscriptions (checker check)


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
    m p


--TODO: need to be exposed somehow
port suggestions : (Response -> msg) -> Sub msg


--TODO: need to be exposed somehow
subscriptions : Model -> Sub Msg
subscriptions model =
  suggestions Suggest

