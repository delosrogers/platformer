#!/bin/bash

git pull
docker compose build
docker compose down
docker compose -f docker-compose.yml -f docker-compose.prod.yml -d up