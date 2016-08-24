module Pong exposing (init, view, update, subscriptions)

import AnimationFrame
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Time exposing (Time)


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
            Ball ( (toFloat boardWidth) / 2, (toFloat boardHeight) / 2 ) 10 ( 75, 2.3 )
            -- TODO: hardcoded ball diameter 10...
            -- TODO: hardcoded ball speed (75, 2.3)...
        , left = leftPlayer
        , right = rightPlayer
        }



-- MSG


type Msg
    = Advance Time



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Advance time ->
            ( advanceWorld model time
            , Cmd.none
            )


advanceWorld : Model -> Time -> Model
advanceWorld model elapsed =
    model
        |> moveBall elapsed
        |> constrainAndFlip


constrainAndFlip : Model -> Model
constrainAndFlip model =
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
                        |> constrain ( 0, 0, width, height )
            }
        else if (x + r) > (toFloat width) || (x - r) < 0 then
            { model
                | ball =
                    model.ball
                        |> flipSpeed Horizontal
                        |> constrain ( 0, 0, width, height )
            }
        else
            model


constrain : ( Int, Int, Int, Int ) -> Ball -> Ball
constrain ( left, top, right, bottom ) ball =
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    AnimationFrame.diffs Advance
