port module DrivebyTest exposing (requests)

import Driveby exposing (..)
import Driveby.Runner exposing (..)
import ButtonTest
import FieldTest


port requests : Request -> Cmd msg


port responses : (Response -> msg) -> Sub msg


main =
    run all requests responses


all : Suite
all =
    suite "All" [ ButtonTest.test1, FieldTest.test1 ]
