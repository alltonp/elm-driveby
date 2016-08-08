port module DrivebyTest exposing (requests)


import Driveby exposing (..)


port requests : Request -> Cmd msg
port responses : (Response -> msg) -> Sub msg


main =
   driveby [test, test2, test3] requests responses


--TODO: should be assert [ "textContains", "#messageList", "Auto Loading Metadata" ]
--TODO: or assert [ "#messageList" "textContains", "Auto Loading Metadata" ]
--TODO: might map well to jquery functions
--TODO: should screenshot be a command? (taking a filepath, would offload more to elm)
--TODO: support TextEquals next
--TODO: make tests more sensible, not just blind C&P and give them names ..
--TODO: need to fail properly on element not found for asserts ...
test : Script
test =
  script "Auto loads metadata on visiting"
    [
      serve "../shoreditch-ui-chrome/chrome"
    , gotoLocal "/elm.html"
    , Command "textContains" [ "#messageList", "Auto Loading Metadata" ]
    --TODO: I should work when messaging fixed
--    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse ([{ url = " ]
    --TODO: probably want to assert the number of checks and actions here ...
    ]

test2 : Script
test2 =
  script "Loads metadata on manual refresh"
    [
      serve "../shoreditch-ui-chrome/chrome"
    , gotoLocal "/elm.html"
    , Command "textContains" [ "#messageList", "Auto Loading Metadata" ]
    --TODO: I should work when messaging fixed
--    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse ([{ url = " ]
    , click "refreshButton"
    , Command "textContains" [ "#messageList", "Manual Loading Metadata" ]
    --TODO: I should work when messaging fixed
--    , Command "textContains" [ "#messageList", "ManualMetaDataRefresh" ]
    ]

test3 : Script
test3 =
  script "Third Test"
    [
      serve "../shoreditch-ui-chrome/chrome"
    , gotoLocal "/elm.html"

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
