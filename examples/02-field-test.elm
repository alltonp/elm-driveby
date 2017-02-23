module FieldTest exposing (..)

import Driveby exposing (..)


allTests : Suite
allTests =
    suite "All" [ test1 ]


test1 : Script
test1 =
    script "TEA 2-field"
        [ serve "examples"
        , gotoLocal "/02-field.html"
        , assert <| textEquals "reversed" ""
        , enter "text" "barry"
        , assert <| textEquals "reversed" "yrrab"
        ]
