#!/bin/bash

git pull
docker compose build
docker compose down
docker commpose -f docker-compose.yml -f docker-compose.prod.yml -d up