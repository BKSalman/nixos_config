#!/usr/bin/env bash

sops exec-file --no-fifo ../../../secrets/secrets.env "docker compose -f immich.yml --env-file {} up -d"
