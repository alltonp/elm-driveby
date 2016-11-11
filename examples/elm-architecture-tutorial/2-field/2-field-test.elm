module FieldTest exposing (..)

import Driveby exposing (..)


allTests : Suite
allTests =
    suite "All" [ test1 ]


test1 : Script
test1 =
    script "TEA 2-field"
        [ serve "examples/elm-architecture-tutorial/2-field"
        , gotoLocal "/2-field.html"
        , assert <| textEquals "reversed" ""
        , enter "text" "barry"
        , assert <| textEquals "reversed" "yrrab"
        ]
