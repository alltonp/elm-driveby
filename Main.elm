port module DrivebyTest exposing (requests)


import Driveby exposing (..)


port requests : Request -> Cmd msg
port responses : (Response -> msg) -> Sub msg


main =
   driveby test [test, test2, test3] requests responses


--TODO: should be assert [ "textContains", "#messageList", "Auto Loading Metadata" ]
--TODO: or assert [ "#messageList" "textContains", "Auto Loading Metadata" ]
--TODO: might map well to jquery functions
--TODO: support multiple tests
--TODO: should screenshot be a command? (taking a filepath, would offload more to elm)
--TODO: support TextEquals next
--TODO: each script could get a default port and stash in context
--TODO: goto could have seconds param base, resolves to localhost:port if unspecified
--TOOD: need a js atomic counter
test : Script
test =
  script "First Test"
    [
      serve "../shoreditch-ui-chrome/chrome" 8080
    , gotoLocal "8080/elm.html"

    , Command "textContains" [ "#messageList", "Auto Loading Metadata" ]
    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse ([{ url = " ]

--    , click "refreshButton"
--    , Command "textContains" [ "#messageList", "ManualMetaDataRefresh" ]

    , enter "configuration" "1"
    , Command "textContains" [ "#messageList", "ConfigurationChanged \"1" ]

    , enter "configuration" "2"
    , Command "textContains" [ "#messageList", "ConfigurationChanged \"12" ]

--    , click "refreshButton"
--    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse []" ]
    ]

test2 : Script
test2 =
  script "Second Test"
    [
      serve "../shoreditch-ui-chrome/chrome" 8081
    , goto "http://localhost:8081/elm.html"

    , Command "textContains" [ "#messageList", "Auto Loading Metadata" ]
    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse ([{ url = " ]

--    , click "refreshButton"
--    , Command "textContains" [ "#messageList", "ManualMetaDataRefresh" ]

    , enter "configuration" "1"
    , Command "textContains" [ "#messageList", "ConfigurationChanged \"1" ]

    , enter "configuration" "2"
    , Command "textContains" [ "#messageList", "ConfigurationChanged \"12" ]

--    , click "refreshButton"
--    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse []" ]
    ]

test3 : Script
test3 =
  script "Third Test"
    [
      serve "../shoreditch-ui-chrome/chrome" 8082
    , goto "http://localhost:8082/elm.html"

    , Command "textContains" [ "#messageList", "Auto Loading Metadata" ]
    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse ([{ url = " ]

--    , click "refreshButton"
--    , Command "textContains" [ "#messageList", "ManualMetaDataRefresh" ]

    , enter "configuration" "1"
    , Command "textContains" [ "#messageList", "ConfigurationChanged \"1" ]

    , enter "configuration" "2"
    , Command "textContains" [ "#messageList", "ConfigurationChanged \"12" ]

--    , click "refreshButton"
--    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse []" ]
    ]
