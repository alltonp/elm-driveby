module Driveby.Runner.Model exposing (..)

import Driveby exposing (..)
import Driveby.Model exposing (..)
import Date exposing (..)
import Dict exposing (..)


type alias Flags =
  { numberOfBrowsers : Int }


-- TODO: ultimately config isn't needed, they become browserIdToScriptId (mainly)
type alias Model =
  { flags : Flags
  , browserIdToScriptId : Dict Int Int
  , scriptIdToExecutableScript : Dict Int ExecutableScript
  }


type alias ExecutableScript =
  { id : Int
  , name : String
  , steps : List Step
  , started : Maybe String {-Date-}
  , finished : Maybe String {-Date-}
  , failures : List String
  }


--TODO: fix all this naming too
type Msg
  = RunAllScripts Date
  | RunNextScript Int String {-Date-}
  | RunNextStep Context
  | Process Response
  | MainLoop Context
  | ScriptFinished String Context

--TODO: add a Finish/AllDone (and do the reporting bit here ...)
