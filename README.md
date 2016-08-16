# elm-driveby

opinionated browser testing in elm

first stab - very experimental, best avoided for a bit

* e.g. (see examples directory for more)

```
port module ButtonTest exposing (requests)


import Driveby exposing (..)
import Driveby.Runner exposing (..)


port requests : Request -> Cmd msg
port responses : (Response -> msg) -> Sub msg


main =
   run allTests requests responses


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
```

#### Setup ####
1. elm-package install alltonpa/elm-driveby
2. [download phantomjs](http://phantomjs.org/download.html)
3. coming soon
