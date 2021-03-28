#!/bin/bash

git pull
docker compose build
docker compose down
docker commpose up -f docker-complse.yml -f docker-compose.prod.yml -d