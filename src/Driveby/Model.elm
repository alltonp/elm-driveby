module Driveby.Model exposing (..)

{-| A Step holding a Command to execute -}
type alias Step =
  { id : Int
  , command : Command
  , executed : Bool
  }


--TODO: consider id/selector being a a first class thing, at least a Maybe ...
--TODO: consider value being a a first class thing, at least a Maybe ...
--TODO: consider expected being a a first class thing, at least a Maybe ...
{-| A Command to execute -}
type alias Command =
  { name : String
  , args : List String
  }


{-| A Condition to check -}
type alias Condition =
  { description : String
  , args : List String
  }


{-| The Context of an executing Script -}
type alias Context =
  { localPort : Int
  , browserId : Int
  , scriptId : Int
  , stepId : Int
  , updated : String
  }