#!/usr/bin/env bash

sops -d ../../../secrets/secrets.env > .env

# docker compose is stupid and needs the .env to be the same name as in the docker-compose.yml file
docker compose -f immich.yml --env-file .env pull

rm .env
