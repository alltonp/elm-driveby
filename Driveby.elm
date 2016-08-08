--TODO: tighten this up ... expose minimum (driveby)
module Driveby exposing (..)

import Driveby.Model exposing (..)
import Driveby.Runner exposing (..)

import Html.App as App
import Html exposing (..)
import Date exposing (..)
import Array exposing (..)

--TODO: ultimately no console sutff in here, report it to js land instead
--when asking for next, just get the next command for the current script, if script is done, get the next script .. etc
--or TEA up the script runners?


driveby : List Script -> (Request -> Cmd Msg) -> ((Response -> Msg) -> Sub Msg) -> Program Flags
driveby scripts requestsPort responsesPort =
  App.programWithFlags
    { init = init scripts
    , view = view
    , update = update requestsPort
    , subscriptions = subscriptions responsesPort
    }


view : Model -> Html Msg
view model =
  div [ ] [ ]



---

unsafeFromString : String -> Date
unsafeFromString dateStr =
  case Date.fromString dateStr of
    Ok date -> date
    Err msg -> Debug.crash("unsafeFromString")


---

script : String -> List Command -> Script
script name commands =
  Script name (
    ( List.append [ Command "init" [] ] commands)
      |> List.indexedMap (,)
      |> List.map (\(i,r) -> Step (toString i) r False))


--TODO: pull out all the other stuff to a runner or engine ...
--TODO: eventually these will be in Driveby.Command or something
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