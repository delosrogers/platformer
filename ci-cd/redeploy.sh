#!/bin/bash

git pull
. .env
export PRIVKEYPATHNODOCKER=~/certs/platformer.genedataexplorer.space/privkey.pem
export PRIVKEYPATHNODOCKER=~/certs/platformer.genedataexplorer.space/fullchain.pem
docker compose down
docker compose build
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d