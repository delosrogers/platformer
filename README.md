[![Netlify Status](https://api.netlify.com/api/v1/badges/40fbfa42-86fd-4868-ba16-54312c2019e4/deploy-status)](https://app.netlify.com/sites/hl-platformer/deploys)
# Platformer

A vertical scroling platformer written in Elm

---

## Running the code

you can run node's `http-server` or similar webserver on the working tree and navigating to `/elm.html`

## Building the code yourself

to build first install elm at https://guide.elm-lang.org/install/elm.html then run `elm make src/Main.elm --output=elm.js --optimize` for a fast release build or you can run with the `--debug` flag for a slower build with the debuger. Next to install the elm-canvas npm library run `npm install .`
