module ButtonTest exposing (..)

import Driveby exposing (..)


all : Suite
all =
    suite "All" [ test1 ]


test1 : Script
test1 =
    script "TEA 1-button"
        [ serve "examples/elm-architecture-tutorial/1-button"
        , gotoLocal "/1-button.html"
        , assert <| textEquals "count" "0"
        , click "increment"
        , assert <| textEquals "count" "1"
        , click "decrement"
        , assert <| textEquals "count" "0"
        ]
