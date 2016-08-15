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
