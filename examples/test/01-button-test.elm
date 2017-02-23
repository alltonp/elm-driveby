module ButtonTest exposing (..)

import Driveby exposing (..)


all : Suite
all =
    suite "All" [ test1 ]


test1 : Script
test1 =
    script "TEA 1-button"
        [ serve "examples"
        , gotoLocal "/01-button.html"
        , assert <| textEquals "count" "0"
        , click "increment"
        , assert <| textEquals "count" "1"
        , click "decrement"
        , assert <| textEquals "count" "0"
        ]
