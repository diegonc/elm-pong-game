module Main exposing (..)

import Html.App as App
import Pong exposing (init, view)


main : Program Never
main =
    App.beginnerProgram
        { model = init 300 50
        , view = view
        , update = curry snd
        }
