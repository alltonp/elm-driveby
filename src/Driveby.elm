module Driveby exposing (..)

{-| This library is for defining scripts to test simple elm web applications using phantomjs

# Definition
@docs Suite, Script, Request, Response

# Common Helpers
@docs suite, script, serve, stub, goto, gotoLocal, click, enter, assert, textContains, textEquals

-}

import Driveby.Model exposing (..)

{-| A Suite of Scripts -}
type alias Suite =
  { name : String
  , scripts : List Script
  }


{-| A Script of Commands to execute -}
type alias Script =
  { name : String
  , commands : List Command
  }


{-| A Request sent to phantomjs -}
type alias Request =
  { context : Context
  , step : Step
  }


{-| A Response sent from phantomjs -}
type alias Response =
  { context : Context
  , failures : List String
  }


{-| create Suite from supplied Scripts -}
suite : String -> List Script -> Suite
suite name scripts =
  Suite name scripts


{-| create Script from supplied Commands -}
script : String -> List Command -> Script
script name commands =
  Script name (
    List.append [ Command "init" [] ] commands)


{-| serve the content under given directory path -}
serve : String -> Command
serve path =
  Command "serve" [path]


--TODO: this should probably have a contentType
{-| stub the content for the requests matching relative path -}
stub : String -> String -> Command
stub path content =
  Command "stub" [path, content]


{-| navigate to this url (for externally hosted) -}
goto : String -> Command
goto url =
  Command "goto" [url]


{-| navigate to this relative path (for content hosted by 'serve') -}
gotoLocal : String -> Command
gotoLocal path =
  Command "gotoLocal" [path]


{-| click this element id -}
click : String -> Command
click id =
  Command "click" ["#" ++ id]


--TODO: this might need to be some kind of keypress abstraction, for modifiers
{-| type value into this element id -}
enter : String -> String -> Command
enter id value =
  Command "enter" ["#" ++ id, value]


{-| assert this condition -}
assert : Condition -> Command
assert condition =
  Command "assert" (List.append [condition.description] condition.args)


{-| check element id text contains expected value -}
textContains : String -> String -> Condition
textContains id expected =
  let
    selector = "#" ++ id
    name = "textContains"
  in
    Condition (selector ++ " " ++ name ++ " '" ++ expected ++ "'") [ selector, name, expected]


{-| check element id text equals expected value -}
textEquals : String -> String -> Condition
textEquals id expected =
  let
      selector = "#" ++ id
      name = "textEquals"
  in
    Condition (selector ++ " " ++ name ++ " '" ++ expected ++ "'") [ selector, name, expected]
