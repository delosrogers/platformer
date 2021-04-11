[![Netlify Status](https://api.netlify.com/api/v1/badges/40fbfa42-86fd-4868-ba16-54312c2019e4/deploy-status)](https://app.netlify.com/sites/hl-platformer/deploys) [![Build](https://github.com/delosrogers/platformer/actions/workflows/build.yml/badge.svg)](https://github.com/delosrogers/platformer/actions/workflows/build.yml)
# Platformer

A vertical scroling platformer written in Elm. You can play the game at https://platformer.genedaataexplorer.space:3000

---

### Dependancies:
- [Elm](https://guide.elm-lang.org/install/elm.html)
- Docker

### Running the code locally

build the elm code by running `elm make src/Main.elm --optimize --output=backend/dist/static/elm.js`.

start the dockerized backend with `docker compose up`.

You can also just use the game without the backend by starting a webserver in the `backend/dist/static` directory and navigating to `/elm.html`.
