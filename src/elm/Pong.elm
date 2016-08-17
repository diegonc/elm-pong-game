module Pong exposing (init, view)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)


-- MODEL


type alias Board =
    { height : Int
    , width : Int
    }


type alias Paddle =
    { position : ( Int, Int )
    , size : Int
    }


type alias Ball =
    { position :
        ( Int, Int )
        -- (x, y)
    , size :
        ( Int, Int )
        -- (width, height)
    , speed :
        ( Float, Float )
        -- (v, θ)
    }


type alias Player =
    { score : Int
    , paddle : Paddle
    }


type alias Model =
    { board : Board
    , ball : Ball
    , left : Player
    , right : Player
    }


aspectRatio : Float
aspectRatio =
    4.0 / 3.0


calculatePaddleWidth : Int -> Int
calculatePaddleWidth height =
    let
        factor =
            0.1
    in
        round <| (toFloat height) * factor


init : Int -> Int -> Model
init boardHeight paddleHeight =
    let
        paddleSpacing =
            5

        boardWidth =
            round <| (toFloat boardHeight) * aspectRatio

        paddleWidth =
            calculatePaddleWidth paddleHeight

        leftPlayer =
            { score = 0
            , paddle = Paddle ( paddleSpacing, boardHeight // 2 ) paddleHeight
            }

        rightPlayer =
            { score = 0
            , paddle =
                Paddle
                    ( boardWidth - paddleWidth - paddleSpacing, boardHeight // 2 )
                    paddleHeight
            }
    in
        { board = Board boardHeight boardWidth
        , ball =
            Ball ( boardWidth // 2, boardHeight // 2 ) ( 10, 10 ) ( 0, 0 )
            -- TODO: hardcoded ball size (10,10)...
        , left = leftPlayer
        , right = rightPlayer
        }



-- VIEW


type alias MyHtml =
    Html Never


view : Model -> MyHtml
view { board, ball, left, right } =
    div [ class "container" ]
        [ div [ class "board", style <| boardStyles board ]
            [ div [ class "container" ]
                [ div [ class "vertical-divider" ] []
                , div [ class "score left" ] [ text <| toString left.score ]
                , div [ class "score right" ] [ text <| toString right.score ]
                , paddleView board left.paddle
                , paddleView board right.paddle
                , ballView ball
                ]
            ]
        ]


boardStyles : Board -> List ( String, String )
boardStyles board =
    [ ( "width", toPx board.width )
    , ( "height", toPx board.height )
    , ( "top", "50%" )
    , ( "left", "50%" )
    , ( "margin-left", toPx <| -(board.width // 2) )
    , ( "margin-top", toPx <| -(board.height // 2) )
    ]


ballView : Ball -> MyHtml
ballView ball =
    let
        ( x, y ) =
            ball.position

        ( w, h ) =
            ball.size
    in
        div
            [ class "ball"
            , style
                [ ( "left", toPx x )
                , ( "top", toPx y )
                , ( "height", toPx h )
                , ( "width", toPx w )
                ]
            ]
            []


paddleView : Board -> Paddle -> MyHtml
paddleView board paddle =
    let
        ( x, y ) =
            paddle.position

        width =
            calculatePaddleWidth paddle.size
    in
        div
            [ class "paddle"
            , style
                [ ( "left", toPx x )
                , ( "top", toPx y )
                , ( "height", toPx paddle.size )
                , ( "width", toPx width )
                ]
            ]
            []


toPx : Int -> String
toPx i =
    (toString i) ++ "px"
