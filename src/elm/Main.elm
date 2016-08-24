module Main exposing (..)

import Html.App as App
import Pong exposing (init, view, update, subscriptions)


main : Program Never
main =
    App.program
        { init = ( init 300 50, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
