# The Pong Game

I'll be writing a Pong clone using the [Elm](http://elm-lang.org) programming
language. The task should be fairly easy but I expect to gain some knowledge
about subscriptions for time and keyboard handling.

I'll also be using a build process based on [Brunch](http://brunch.io/) for
the first time.

# 0. Setting up brunch

Brunch is a build tool for the front-end that promises small and declarative
configuration files and fast builds. I heard of it at on of the channels hosted
by Elm's Slack team.

First, installing Brunch itself; it's just a globally installable NPM module
`npm install -g brunch`.

The next step is to create the project using `branch new`. Brunch allows to
specify a *skeleton* used to generate the files. There are skeletons for
ECMAScript 6, React, TypeScript and [more](http://brunch.io/skeletons).

For Elm, there already exist two skeletons:
* [Brunch with Elm](https://github.com/alaister/brunch-with-elm)
* [Elm 0.17 with Sass & Bootstrap 4](https://github.com/mathieul/brunch-with-elm-bootstrap)

I'll use none though. Both include SASS which I won't use and they prefer the
`app` name for the source folder instead of `src`. Nonetheless, the first one
will serve as a good guideline for what is needed.

Thus, I'll just use the `es6` skeleton as a starting point
```
$ brunch new -s es6
```
then I'll install `elm-brunch` package.
```
$ npm install --save-dev elm-brunch
```

Having a look at the *Brunch with Elm* skeleton, first I need to do some
configuration in `brunch-config.js`.
* Set the `files` section to generate unified js and css bundles. And drop
the vendor stuff.
* Configure *elm-brunch* plugin by adding an `elmBrunch` field to the
plugins section; where the main modules and elm make parameters are
specified and the output file set to a unified bundle named `elm-app.js`.
* As per *elm-brunch* readme, watch our `src` directory by
adding the `paths.watch` field to the configuration file.

Also in package.json
* Add a `postinstall` script that will run *elm package install* to
generate the *elm-stuff* directory.

> **Note**
>
>    I'd like to bundle both JS and Elm code into one minified
>    file; but I need to investigate how.
>
>    Currently Elm code is compiled to one file and JS code to
>    another. Production builds will only minify JS code.

# 1. A Static Pong: planning the Model and View

The game presents its users just a few onscreen elements
* the scoreboard
* the table with a vertical division at its half
* the ball
* two paddles, one on each side of the table

Wikipedia's Pong page gives some insight into the mechanics of
game play
* paddle divided into eight segments to change the ball's angle of return

        +--+
        |  | z          Where
        |  | y            90 > x > y > z > 0
        |  | x
        |  | 90°
        |  | 90°
        |  | x
        |  | y
        |  | z
        +--+

* the ball accelerates the longer it remains in play; missing the ball reset
the speed
* paddles are unable to reach the top of screen. (I'll do the same
for the bottom)

I'll assume the board aspect ratio to be 4:3 and to simplify the code the view
will use a 1:1 scale.

### Model

With the above in mind, a sketch of the model can be produced.
There needs to be a board of a given size, the left and right
player scores, the left and right paddles' position and size
and the ball position and speed vectors. Maybe a paused state too.

I'll define the following type aliases which will be contained by the
top-level `Model` record. I'm doing this to get a feel of how nested
record updating works in Elm.

```elm
type alias Board =
  {
    height: Int
  , width : Int
  }
```

```elm
type alias Paddle =
  {
    position: (Int, Int)
  , size    : Int
  }
```

```elm
type alias Ball =
  {
    position: (Int, Int)     -- (x, y)
  , speed   : (Float, Float) -- (v, θ)
  }
```

```elm
type alias Player =
  {
    score : Int
  , paddle: Paddle
  }
```

And finally the `Model` type is
```elm
type alias Model =
  {
    board: Board
  , ball: Ball
  , left: Player
  , right: Player
  }
```

### View

The view is quite simple, it just consists of nested `div`s that are
absolute positioned and whose `left` and `top` properties are adjusted
according to the model.

    div.container
      div.board
        div.container
          div.vertical-divider
          div.left-score
          div.right-score
          div.left-paddle
          div.right-paddle
          div.ball

`container`s are relative positioned while other divs have absolute position.

# 2. Let the Ball Move: using subscriptions for animation

Subscriptions allow Elm programs to be notified of external events they
are interested in. The `program` function from the `Html.App` module allows
the programmer to specify a subscription function which takes the model and
returns to the runtime the subscriptions that must be established.

Then the Elm's runtime will call our update function with the configured
message every time there's an event available.

To animate the ball we need to give it an initial speed and subscribe to
request animation frame events to update its position. The relevant package
is `elm-lang/animation-frame`, which provides a `diffs` function to create
a subscription that will notify on each frame providing the elapsed time.

A new update function and accompanying message type shall be introduced
to handle those events.

```elm
type Msg
    = Advance Time
```

The subscriptions must be requested by writing and handing in a function
to `program` from `Html.App`.

```elm
subscriptions : Model -> Sub Msg
subscriptions model =
    AnimationFrame.diffs Advance
```

And then the `update` function should respond to the `Advance` message by
adjusting the ball position according to the elapsed time and its speed and
checking collisions with the board.

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Advance time ->
            ( advanceWorld model time
            , Cmd.none
            )
```

where `advanceWorld` is a function calculating the physics of the Pong game.

# 3. Use the Paddle, Willy: keyCodes and the downs and ups subscriptions

The `Keyboard` module provides subscriptions to the stream of Keyboard
related events like key downs, presses and ups.

> **Note** after a brief exploration of the `presses` subscription
> I discovered that simultaneous key presses will not trigger the
> repetition of `keypress` events for both keys but only for the last one.
>
> Thus, the following section will use `keydown` to set the paddle speed
> in the model and `keyup` to reset it to zero. The animation will then
> update the position of the paddles when updating the world.
>
> It's a bit more complicated but a least both paddles will be able to
> to be moved at the same time. :smile:

The `Keyboard.downs` function creates a subscription that posts a
message on each keydown event. The message payload is the character produced
by the keyCode property of the event object, as computed by the `fromCode`
function from the `Char` module.

Likewise, the `Keyboard.ups` function gives a subscription for keyup events.
Again, the message is going to hold the corresponding character.

The following keys will be assigned to actions on the paddles:
* Q -> left paddle up
* A -> left paddle down
* O -> right paddle up
* L -> right paddle down

> **Note** characters given by `Char.fromCode` are _uppercased_.

So the `Msg` type needs to have `KeyDown` and `KeyUp` cases to handle those new
messages.

```elm
type Msg
    = Advance Time
    | KeyDown Char
    | KeyUp Char
```

And the `subscriptions` function needs to be updated to return the `Sub`s
given by `downs` and `ups`. But those subscriptions need to be running at the
same time as the `AnimationFrame.diffs` introduced in the previous section;
`Sub.batch` is the function that composes a list of unrelated subscriptions
into one `Sub` value that can be returned.

```elm
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
      [ AnimationFrame.diffs Advance
      , Keyboard.downs (Char.fromCode >> KeyDown)
      , Keyboard.ups (Char.fromCode >> KeyUp)
      ]
```

Now the update function needs to handle the new messages otherwise
the compiler will reject the code.

Update will just set the speed of the paddle while `updateWorld` will handle
the calculation of its position on every tick.

```elm
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ...
    KeyUp key ->
      case key of
        'Q' -> (stopPaddle Left model, Cmd.none)
        'A' -> (stopPaddle Left model, Cmd.none)
        'O' -> (stopPaddle Right model, Cmd.none)
        'L' -> (stopPaddle Right model, Cmd.none)
        _ -> (model, Cmd.none)
    KeyDown key ->
      case key of
        'Q' -> (speedPaddle Left Up model, Cmd.none)
        'A' -> (speedPaddle Left Down model, Cmd.none)
        'O' -> (speedPaddle Right Up model, Cmd.none)
        'L' -> (speedPaddle Right Down model, Cmd.none)
        _ -> (model, Cmd.none)
```

where two types where introduced to avoid spreading the specific key
all over the application: `WhichPaddle` and `WhichDirection`.

```elm
type WhichPaddle
    = Left
    | Right


type WhichDirection
    = Up
    | Down
```

`speedPaddle` will set the speed of the given paddle to some positive or
negative value depending on the requested direction. `stopPaddle` will set
the speed of the given paddle back to zero.

`advanceWorld` needs to be taught how to move and constrain the paddles.
