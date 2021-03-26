elm make src/Main.elm --output=backend/dist/static/elm.js --optimize
cd backend
export NODE_ENV=production
npm start