module Pong exposing (init, view, update, subscriptions)

import AnimationFrame
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Time exposing (Time)
import Keyboard
import Char


-- MODEL


type alias Board =
    { height : Int
    , width : Int
    }


type alias Paddle =
    { position : ( Float, Float )
    , speed : ( Float, Float )
    , size : Int
    }


type alias Ball =
    { position :
        ( Float, Float )
        -- (x, y)
    , diameter :
        Int
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


calculatePaddleWidth : Int -> Float
calculatePaddleWidth height =
    let
        factor =
            0.1
    in
        (toFloat height) * factor


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
            , paddle =
                Paddle
                    ( paddleSpacing, (toFloat boardHeight) / 2 )
                    ( 0, 0 )
                    paddleHeight
            }

        rightPlayer =
            { score = 0
            , paddle =
                Paddle
                    ( (toFloat boardWidth) - paddleWidth - paddleSpacing, (toFloat boardHeight) / 2 )
                    ( 0, 0 )
                    paddleHeight
            }
    in
        { board = Board boardHeight boardWidth
        , ball =
            Ball ( (toFloat boardWidth) / 2, (toFloat boardHeight) / 2 ) 10 ( 75, 2.3 )
            -- TODO: hardcoded ball diameter 10...
            -- TODO: hardcoded ball speed (75, 2.3)...
        , left = leftPlayer
        , right = rightPlayer
        }



-- MSG


type Msg
    = Advance Time
    | KeyUp Char
    | KeyDown Char



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Advance time ->
            ( advanceWorld model time
            , Cmd.none
            )

        KeyUp key ->
            case key of
                'Q' ->
                    ( stopPaddle Left model, Cmd.none )

                'A' ->
                    ( stopPaddle Left model, Cmd.none )

                'O' ->
                    ( stopPaddle Right model, Cmd.none )

                'L' ->
                    ( stopPaddle Right model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        KeyDown key ->
            case key of
                'Q' ->
                    ( speedPaddle Left Up model, Cmd.none )

                'A' ->
                    ( speedPaddle Left Down model, Cmd.none )

                'O' ->
                    ( speedPaddle Right Up model, Cmd.none )

                'L' ->
                    ( speedPaddle Right Down model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


type WhichPaddle
    = Left
    | Right


type WhichDirection
    = Up
    | Down


speedPaddle : WhichPaddle -> WhichDirection -> Model -> Model
speedPaddle whichPaddle whichDirection model =
    let
        speed =
            case whichDirection of
                Up ->
                    ( 0, -120 )

                Down ->
                    ( 0, 120 )
    in
        case whichPaddle of
            Left ->
                { model
                    | left = setPlayerPaddleSpeed speed model.left
                }

            Right ->
                { model
                    | right = setPlayerPaddleSpeed speed model.right
                }


stopPaddle : WhichPaddle -> Model -> Model
stopPaddle whichPaddle model =
    case whichPaddle of
        Left ->
            let
                player =
                    model.left
            in
                { model | left = setPlayerPaddleSpeed ( 0, 0 ) player }

        Right ->
            let
                player =
                    model.right
            in
                { model | right = setPlayerPaddleSpeed ( 0, 0 ) player }


setPlayerPaddleSpeed : ( Float, Float ) -> Player -> Player
setPlayerPaddleSpeed speed p =
    let
        paddle =
            p.paddle

        newPaddle =
            { paddle | speed = speed }
    in
        { p | paddle = newPaddle }


advanceWorld : Model -> Time -> Model
advanceWorld model elapsed =
    model
        |> movePaddles elapsed
        |> constrainPaddles
        |> moveBall elapsed
        |> constrainAndFlipBall


movePaddles : Time -> Model -> Model
movePaddles elapsed model =
    { model
        | left = movePlayerPaddle elapsed model.left
        , right = movePlayerPaddle elapsed model.right
    }


movePlayerPaddle : Time -> Player -> Player
movePlayerPaddle elapsed player =
    { player | paddle = movePaddle elapsed player.paddle }


movePaddle : Time -> Paddle -> Paddle
movePaddle elapsed paddle =
    let
        ( vx, vy ) =
            paddle.speed

        ( x, y ) =
            paddle.position

        dt =
            Time.inSeconds elapsed

        newPosition =
            ( x {- ignore x speed ... + vx * dt -}, y + vy * dt )
    in
        { paddle | position = newPosition }


constrainPaddles : Model -> Model
constrainPaddles model =
    { model
        | left = constrainPlayerPaddle model.board model.left
        , right = constrainPlayerPaddle model.board model.right
    }


constrainPlayerPaddle : Board -> Player -> Player
constrainPlayerPaddle board player =
    { player | paddle = constrainPaddle board player.paddle }


constrainPaddle : Board -> Paddle -> Paddle
constrainPaddle board paddle =
    let
        -- spacing from the top/bottom of the board
        gap =
            (toFloat paddle.size) * 0.02

        -- spacing from half of the paddle to its borders
        halfSize =
            toFloat paddle.size

        height =
            toFloat board.height

        ( x, y ) =
            paddle.position

        newY =
            if (y - halfSize) < gap then
                gap + halfSize
            else if (y + halfSize + gap) > height then
                height - gap - halfSize
            else
                y
    in
        { paddle | position = ( x, newY ) }


constrainAndFlipBall : Model -> Model
constrainAndFlipBall model =
    let
        ( x, y ) =
            model.ball.position

        r =
            (toFloat model.ball.diameter) / 2

        { height, width } =
            model.board
    in
        if (y + r) > (toFloat height) || (y - r) < 0 then
            { model
                | ball =
                    model.ball
                        |> flipSpeed Vertical
                        |> constrainBall ( 0, 0, width, height )
            }
        else if (x + r) > (toFloat width) || (x - r) < 0 then
            { model
                | ball =
                    model.ball
                        |> flipSpeed Horizontal
                        |> constrainBall ( 0, 0, width, height )
            }
        else
            model


constrainBall : ( Int, Int, Int, Int ) -> Ball -> Ball
constrainBall ( left, top, right, bottom ) ball =
    let
        r =
            (toFloat ball.diameter) / 2

        newX =
            ball.position
                |> fst
                |> min ((toFloat right) - r)
                |> max ((toFloat left) + r)

        newY =
            ball.position
                |> snd
                |> min ((toFloat bottom) - r)
                |> max ((toFloat top) + r)
    in
        { ball | position = ( newX, newY ) }


type FlipAxis
    = Horizontal
    | Vertical


flipSpeed : FlipAxis -> Ball -> Ball
flipSpeed axis ball =
    let
        ( vx, vy ) =
            fromPolar ball.speed
    in
        case axis of
            Horizontal ->
                { ball | speed = toPolar ( -vx, vy ) }

            Vertical ->
                { ball | speed = toPolar ( vx, -vy ) }


moveBall : Time -> Model -> Model
moveBall elapsed model =
    let
        dt =
            Time.inSeconds elapsed

        ( vx, vy ) =
            fromPolar model.ball.speed

        dx =
            model.ball.position
                |> fst
                |> (+) (vx * dt)

        dy =
            model.ball.position
                |> snd
                |> (+) (-vy * dt)

        ball =
            model.ball

        newBall =
            { ball | position = ( dx, dy ) }
    in
        { model | ball = newBall }



-- VIEW


view : Model -> Html Msg
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


ballView : Ball -> Html a
ballView ball =
    let
        ( x, y ) =
            ball.position
    in
        div
            [ class "ball"
            , style
                [ ( "left", toPx (round x) )
                , ( "top", toPx (round y) )
                , ( "height", toPx ball.diameter )
                , ( "width", toPx ball.diameter )
                ]
            ]
            []


paddleView : Board -> Paddle -> Html a
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
                [ ( "left", toPx <| round x )
                , ( "top", toPx <| round y )
                , ( "height", toPx paddle.size )
                , ( "width", toPx <| round width )
                ]
            ]
            []


toPx : Int -> String
toPx i =
    (toString i) ++ "px"



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.diffs Advance
        , Keyboard.downs (Char.fromCode >> KeyDown)
        , Keyboard.ups (Char.fromCode >> KeyUp)
        ]
