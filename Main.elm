port module DrivebyTest exposing (commands)


import Driveby exposing (..)


port commands : Step -> Cmd msg
port results : (Response -> msg) -> Sub msg


main =
   driveby test commands results


--TODO: should be assert [ "textContains", "#messageList", "Auto Loading Metadata" ]
--TODO: or assert [ "#messageList" "textContains", "Auto Loading Metadata" ]
--TODO: might map well to jquery functions
--TODO: support multiple tests
--TODO: should screenshot be a command? (taking a filepath, would offload more to elm)
--TODO: support TextEquals next
test : Script
test =
  script "First Test"
    [
      serve "../shoreditch-ui-chrome/chrome" 8080
    , goto "http://localhost:8080/elm.html"

    , Command "textContains" [ "#messageList", "Auto Loading Metadata" ]
    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse ([{ url = " ]

--    , click "refreshButton"
--    , Command "textContains" [ "#messageList", "ManualMetaDataRefresh" ]

    , Command "enter" [ "#configuration", "1" ]
    , Command "textContains" [ "#messageList", "ConfigurationChanged \"1" ]

    , Command "enter" [ "#configuration", "2" ]
    , Command "textContains" [ "#messageList", "ConfigurationChanged \"12" ]

--    , click "refreshButton"
--    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse []" ]
    ]
