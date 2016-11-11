module Driveby.Model exposing (..)


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
