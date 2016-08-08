port module DrivebyTest exposing (requests)


import Driveby exposing (..)
import Driveby.Model exposing (..)


port requests : Request -> Cmd msg
port responses : (Response -> msg) -> Sub msg


main =
   driveby [test, test2, test3] requests responses


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
    [ serve "../shoreditch-ui-chrome/chrome"
    , stub "/reservations/metadata" "meh"
    , gotoLocal "/elm.html"
    , textContains "messageList" "Auto Loading Metadata----"
    --TODO: I should work when messaging fixed
--    , textContains "messageList" "LoadAllMetaDataResponse ([{ url = "
    --TODO: probably want to assert the number of checks and actions here ...
    ]

test2 : Script
test2 =
  script "Loads metadata on manual refresh"
    [ serve "../shoreditch-ui-chrome/chrome"
    , stub "/reservations/metadata" "meh"
    , gotoLocal "/elm.html"
    , textContains "messageList" "Auto Loading Metadata"
    --TODO: I should work when messaging fixed
--    , textContains "messageList" "LoadAllMetaDataResponse ([{ url = "
    , click "refreshButton"
    , textContains "messageList" "Manual Loading Metadata"
    --TODO: I should work when messaging fixed
--    , textContains "messageList" "ManualMetaDataRefresh"
    ]

test3 : Script
test3 =
  script "Detects configuration changes"
    [ serve "../shoreditch-ui-chrome/chrome"
    , stub "/reservations/metadata" "meh"
    , gotoLocal "/elm.html"
    , textContains "messageList" "Auto Loading Metadata"
    --TODO: I should work when messaging fixed
--    , textContains "messageList" "LoadAllMetaDataResponse ([{ url = "
    , enter "configuration" "1"
    --TODO: I should work when messaging fixed
--    , textContains "messageList" "ConfigurationChanged \"1"
    , textContains "messageList" "Config changed"
    , enter "configuration" "2"
    --TODO: I should work when messaging fixed
--    , textContains "messageList" "ConfigurationChanged \"12"
    , textContains "messageList" "Config changed"
    ]

test4 : Script
test4 =
  script "Fails causing build to hang"
    [ serve "../shoreditch-ui-chrome/chrome"
    , stub "/reservations/metadata" "meh"
    , gotoLocal "/elm2.html"
    , textContains "messageList" "Auto Loading Metadata"
    ]


--TODO: add missing test for a stubbed Check in metadata
--TODO: add missing test for a stubbed Action in metadata
--TODO: add missing test for a stubbed Check with args in metadata
--TODO: add missing test for a stubbed Action with args in metadata