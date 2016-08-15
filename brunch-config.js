module.exports = {
  paths: {
    watched: ['src']
  },
  files: {
    javascripts: {
      joinTo: 'js/bundle.js'
    },
    stylesheets: {joinTo: 'css/bundle.css'}
  },

  plugins: {
    babel: {presets: ['es2015']},
    elmBrunch: {
      outputFile: 'elm-app.js',
      mainModules: ['src/elm/Main.elm'],
      makeParameters: ['--warn']
    }
  }
};
