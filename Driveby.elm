module Driveby exposing (..)

import Driveby.Model exposing (..)
import Driveby.Runner as Runner
import Html.App as App


--TODO: ultimately no console sutff in here, report it to js land instead
--TODO: should be assert [ "textContains", "#messageList", "Auto Loading Metadata" ]
--TODO: or assert [ "#messageList" "textContains", "Auto Loading Metadata" ]
--TODO: might map well to jquery functions
--TODO: should screenshot be a command? (taking a filepath, would offload more to elm)
--TODO: support TextEquals next
--TODO: need to fail properly when a script fails ...
--TODO: idealy we'd have the public commands and the model in the top level thing, so only 1 import ...

run : List Script -> (Request -> Cmd Runner.Msg) -> ((Response -> Runner.Msg) -> Sub Runner.Msg) -> Program Runner.Flags
run scripts requestsPort responsesPort =
  App.programWithFlags
    { init = Runner.init scripts
    , view = Runner.view
    , update = Runner.update requestsPort
    , subscriptions = Runner.subscriptions responsesPort
    }


--unsafeFromString : String -> Date
--unsafeFromString dateStr =
--  case Date.fromString dateStr of
--    Ok date -> date
--    Err msg -> Debug.crash("unsafeFromString")
--

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