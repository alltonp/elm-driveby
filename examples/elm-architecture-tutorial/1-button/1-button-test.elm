--port module ButtonTest exposing (requests)
module ButtonTest exposing (..)


import Driveby exposing (..)
import Driveby.Runner exposing (..)


--port requests : Request -> Cmd msg
--port responses : (Response -> msg) -> Sub msg


--main =
--   run allTests requests responses


allTests : Suite
allTests =
  suite "All" [test1]


test1 : Script
test1 =
  script "elm-architecture-tutorial 1-button"
    [ serve "examples/elm-architecture-tutorial/1-button"
    , gotoLocal "/1-button.html"
    , assert <| textEquals "count" "0"
    , click "increment"
    , assert <| textEquals "count" "1"
    , click "decrement"
    , assert <| textEquals "count" "0"
    ]
