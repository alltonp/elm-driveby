module Driveby exposing (..)

import Driveby.Model exposing (..)


type alias Script =
  { name : String
  , steps : List Step
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
    ( List.append [ Command "init" [] ] commands)
      |> List.indexedMap (,)
      |> List.map (\(i,r) -> Step (toString i) r False))


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