# elm-driveby

opinionated browser testing in elm - usable but experimental

### Setup ###
1. ```elm-package install alltonpa/elm-driveby```
2. [download phantomjs](http://phantomjs.org/download.html)
3. That's it!

### Writing a Script ###

1. Create a Script - ExampleTest.elm

 ```
 module ExampleTest exposing (..)


 import Driveby exposing (..)


 all : Suite
 all =
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


2. Create a main to run the script - Example.elm

 ```
 port module Example exposing (requests)


 import Driveby.Runner exposing (..)
 import ExampleTest


 port requests : Request -> Cmd msg
 port responses : (Response -> msg) -> Sub msg


 main =
   run ButtonTest.all requests responses
```

3. Compile

```
elm-make Example.elm --output tests.js
```


#### Run ###
1. phantomjs elm-stuff/packages/alltonp/elm-driveby/x.x.x/driveby.js tests.js
(PA: make tests.js a config option ...)