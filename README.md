# elm-driveby

opinionated browser testing in elm - experimental, but definitely usable

### Setup ###
1. ```elm-package install alltonp/elm-driveby```
2. [download a phantomjs executable](http://phantomjs.org/download.html)
3. That's it!


### Running example Scripts ###
1. cd elm-stuff/packages/alltonp/elm-driveby/x.x.x
2. build example apps
```elm-make examples/src/01-button.elm --output examples/build/01-button.html```
```elm-make examples/src/02-field.elm --output examples/build/02-field.html```
3. build all the tests
```elm-make examples/tests/AllTests.elm --output examples/build/tests.js```
4. run the tests
```{path-to-phantom}/phantomjs driveby.js examples/build/tests.js```

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
   run ExampleTest.all requests responses
```

3. Compile

```
elm-make Example.elm --output tests.js
```


### Run ###
1. compile the application - ```elm-make elm-stuff/packages/alltonp/elm-driveby/x.x.x/1-button.elm --output 1-button.html```
2. compile the tests - ```elm-make elm-stuff/packages/alltonp/elm-driveby/x.x.x/1-button-test.elm --output tests.js```
3. phantomjs elm-stuff/packages/alltonp/elm-driveby/x.x.x/driveby.js tests.js

1. compile the application - ```elm-make examples/elm-architecture-tutorial/1-button/1-button.elm --output 1-button.html```
2. compile the tests - ```elm-make examples/elm-architecture-tutorial/1-button/1-button-test.elm --output tests.js```
3. ./phantomjs driveby.js tests.js

TODO:
- make tests.js a config option ...
- check we don't need Driveby import in Example.elm
- make example be non hosted
- explain features first
