[![Netlify Status](https://api.netlify.com/api/v1/badges/40fbfa42-86fd-4868-ba16-54312c2019e4/deploy-status)](https://app.netlify.com/sites/hl-platformer/deploys) [![Build](https://github.com/delosrogers/platformer/actions/workflows/build.yml/badge.svg)](https://github.com/delosrogers/platformer/actions/workflows/build.yml)
# Platformer

A vertical scroling platformer written in Elm. You can play the game at https://hl-platformer.netlify.app/elm.html

---

### Dependancies:
- Node
- [Elm](https://guide.elm-lang.org/install/elm.html)
- Docker (or another install of MongoDB)

### Running the code locally

run `npm run tmp-db` in the backend directory to start a new MongoDB Docker container and start the web app. If you already have Mongo running on `localhost:27017` run `build.sh` for a release build or `build-dev.sh` for a debug build. Next, navigate to `http://localhost:3000/elm.html` to play the game.

To put a dummy user in the database run `create-dummy-user.sh`.
