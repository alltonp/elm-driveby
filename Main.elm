port module DrivebyTest exposing (commands)


import Driveby exposing (..)


port commands : Step -> Cmd msg
port results : (Response -> msg) -> Sub msg


main =
   driveby test commands results


--TODO: specify this using functions, to ensure the correct args ... click id etc
--TODO: ensure the Script top level has a description ..
--TODO: should be assert [ "textContains", "#messageList", "Auto Loading Metadata" ]
--TODO: or assert [ "#messageList" "textContains", "Auto Loading Metadata" ]
--TODO: might map well to jquery functions
--TODO: support multiple tests
test : List Step
test =
    [ serve "../shoreditch-ui-chrome/chrome" 8080
    , goto "http://localhost:8080/elm.html"
    , Request "textContains" [ "#messageList", "Auto Loading Metadata" ]
    , Request "click" [ "#refreshButton" ]
    , Request "textContains" [ "#messageList", "ManualMetaDataRefresh" ]
    ]
    --TODO: this bit should be internal
    |> List.indexedMap (,)
    |> List.map (\(i,r) -> Step (toString i) r False)



serve : String -> Int -> Request
serve path onPort =
   Request "serve" [path, toString onPort]


goto : String -> Request
goto url =
   Request "goto" [url]