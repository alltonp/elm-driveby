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

--TODO: stubs ..
--content:
--{
--  "name":"Reservations System",
--  "alias":"res",
--  "version":"10001",
--  "checks":[{
--    "url":"reservations/check/reservation/confirmed/@pnr"
--  }],
--  "actions":[]
--}

--TODO: these tests should live in shoreditch-chrome-ui project

test : Script
test =
  script "Auto loads metadata on visiting"
    [
      serve "../shoreditch-ui-chrome/chrome"
    , stub "/reservations/metadata" "meh"
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
    , stub "/reservations/metadata" "meh"
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
  script "Detects configuration changes"
    [
      serve "../shoreditch-ui-chrome/chrome"
    , stub "/reservations/metadata" "meh"
    , gotoLocal "/elm.html"
    , Command "textContains" [ "#messageList", "Auto Loading Metadata" ]
    --TODO: I should work when messaging fixed
--    , Command "textContains" [ "#messageList", "LoadAllMetaDataResponse ([{ url = " ]
    , enter "configuration" "1"
    --TODO: I should work when messaging fixed
--    , Command "textContains" [ "#messageList", "ConfigurationChanged \"1" ]
    , Command "textContains" [ "#messageList", "Config changed" ]
    , enter "configuration" "2"
    --TODO: I should work when messaging fixed
--    , Command "textContains" [ "#messageList", "ConfigurationChanged \"12" ]
    , Command "textContains" [ "#messageList", "Config changed" ]
    ]
