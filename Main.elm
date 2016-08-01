port module DrivebyTest exposing (commands)
--command?
--result?

import Driveby exposing (..)


main =
   driveby test subscriptions (checker commands)


port commands : Step -> Cmd msg

--check : Msg -> (Step -> Cmd msg)
checker m p =
    m p


port results : (Response -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
  results Suggest



--TODO: specify this using functions, to ensure the correct args ... click id etc
--TODO: ensure the Script top level has a description ..
--TODO: should be assert [ "textContains", "#messageList", "Auto Loading Metadata" ]
--TODO: or assert [ "#messageList" "textContains", "Auto Loading Metadata" ]
--TODO: might map well to jquery functions
test : List Step
test =
    [ Request "serve" [ "../shoreditch-ui-chrome/chrome", "8080" ]
    , Request "goto" [ "http://localhost:8080/elm.html" ]
    , Request "textContains" [ "#messageList", "Auto Loading Metadata" ]
    , Request "click" [ "#refreshButton" ]
    , Request "textContains" [ "#messageList", "ManualMetaDataRefresh" ]
    ]
    |> List.indexedMap (,)
    |> List.map (\(i,r) -> Step (toString i) r False)


