module Driveby.Runner.Model exposing (..)

import Driveby exposing (..)
import Date exposing (..)
import Dict exposing (..)


type alias Flags =
  { browsers : Int }


--TODO: can we not just use Flags instead?
type alias Config =
  { numberOfBrowsers : Int }


-- TODO: ultimately config isn't needed, they become browserIdToScriptId (mainly)
type alias Model =
  { config : Config
  , browserIdToScriptId : Dict Int Int
  , scriptIdToExecutableScript : Dict Int ExecutableScript
  }


type alias ExecutableScript =
  { script: Script
  , id : Int
  , started : Maybe String {-Date-}
  , finished : Maybe String {-Date-}
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
