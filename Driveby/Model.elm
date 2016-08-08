module Driveby.Model exposing (..)

a : String
a = ""

type alias Script =
  { name : String
  , steps : List Step
  }

--TODO: this should probably be Request and requestId everywhere ...
--TODO: can this id die, I'm not sure yet ...
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
