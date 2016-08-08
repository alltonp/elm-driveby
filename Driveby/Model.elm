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


type alias Context =
  { localPort : Int
  , browserId : Int
  , scriptId : String
  , stepId : Int
  , updated : String
  }
