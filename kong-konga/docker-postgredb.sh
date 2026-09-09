#!/bin/bash

docker run --name postgres-db \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-change-me} \
  -e POSTGRES_DB=postgres-kong-db \
  -p 5432:5432 \
  -d postgres:11.16