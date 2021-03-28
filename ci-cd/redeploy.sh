#!/bin/bash

git pull
docker compose build
docker compose down
docker commpose up -d