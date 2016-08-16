module Driveby exposing (..)


type alias Suite =
  { name : String
  , scripts : List Script
  }


type alias Script =
  { name : String
  , commands : List Command
  }


type alias Request =
  { context : Context
  , step : Step
  }


type alias Response =
  { context : Context
  , failures : List String
  }


suite : String -> List Script -> Suite
suite name scripts =
  Suite name scripts


script : String -> List Command -> Script
script name commands =
  Script name (
    List.append [ Command "init" [] ] commands)


serve : String -> Command
serve path =
  Command "serve" [path]


--TODO: this should probably have a contentType
stub : String -> String -> Command
stub path content =
  Command "stub" [path, content]


goto : String -> Command
goto url =
  Command "goto" [url]


gotoLocal : String -> Command
gotoLocal path =
  Command "gotoLocal" [path]


click : String -> Command
click id =
  Command "click" ["#" ++ id]


--TODO: this might need to be some kind of keypress abstraction, for modifiers
enter : String -> String -> Command
enter id value =
  Command "enter" ["#" ++ id, value]


assert : Condition -> Command
assert condition =
  Command "assert" (List.append [condition.description] condition.args)


textContains : String -> String -> Condition
textContains id expected =
  let
    selector = "#" ++ id
    name = "textContains"
  in
    Condition (selector ++ " " ++ name ++ " '" ++ expected ++ "'") [ selector, name, expected]


textEquals : String -> String -> Condition
textEquals id expected =
  let
      selector = "#" ++ id
      name = "textEquals"
  in
    Condition (selector ++ " " ++ name ++ " '" ++ expected ++ "'") [ selector, name, expected]


----------

--TODO: this should probably be Request and requestId everywhere ...
--TODO: can this id die, I'm not sure yet ...
--TODO: this feels more like Runner.Model
type alias Step =
  { id : Int
  , command : Command
  , executed : Bool
  }


--TODO: consider id/selector being a a first class thing, at least a Maybe ...
--TODO: consider value being a a first class thing, at least a Maybe ...
--TODO: consider expected being a a first class thing, at least a Maybe ...
type alias Command =
  { name : String
  , args : List String
  }


type alias Condition =
  { description : String
  , args : List String
  }


type alias Context =
  { localPort : Int
  , browserId : Int
  , scriptId : Int
  , stepId : Int
  , updated : String
  }