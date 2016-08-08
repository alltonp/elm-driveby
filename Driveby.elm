module Driveby exposing (..)


type alias Script =
  { name : String
--  , steps : List Step
  , commands : List Command
  }


--TODO: try to lose/inline Step if we can
--if steps were an array, could it just be the index? or recipe for equality issues?
type alias Request =
  { step : Step
  , context : Context
  }


--TODO: consider Id as a type and give it the bits it needs ...
--TODO: rename to Result or Outcome
type alias Response =
  { id : String
  , context : Context
  , failures : List String
  }


script : String -> List Command -> Script
script name commands =
  Script name (
    List.append [ Command "init" [] ] commands)
--      |> List.indexedMap (,)
--      |> List.map (\(i,r) -> Step (toString i) r False))


serve : String -> Command
serve path =
  Command "serve" [path]


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


enter : String -> String -> Command
enter id value =
  Command "enter" ["#" ++ id, value]


textContains : String -> String -> Command
textContains id expected =
  Command "textContains" [ "#" ++ id, expected]


----------

--TODO: this should probably be Request and requestId everywhere ...
--TODO: can this id die, I'm not sure yet ...
--TODO: this feels more like Runner.Model
type alias Step =
  { id : String
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


type alias Context =
  { localPort : Int
  , browserId : Int
  , scriptId : Int
  , stepId : Int
  , updated : String
  }