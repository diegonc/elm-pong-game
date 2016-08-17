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
