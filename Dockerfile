FROM node:15.12.0-alpine3.13
COPY backend/package.json /app/backend/package.json
COPY backend/package-lock.json /app/backend/package-lock.json
COPY backend/tsconfig.json /app/backend/tsconfig.json
WORKDIR /app/backend
RUN npm install .
COPY backend /app/backend
EXPOSE 3000
CMD npm start
