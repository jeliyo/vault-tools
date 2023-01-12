#!/usr/bin/env bash

docker run \
       --name postgres \
       --env POSTGRES_USER=root \
       --env POSTGRES_PASSWORD=rootpassword \
       --detach \
       --rm \
       --publish 5432:5432 \
       postgres

until [ "`docker inspect -f {{.State.Running}} postgres`"=="true" ]; do
    sleep 0.1;
done;

sleep 2

docker exec -it postgres psql -c "CREATE ROLE ro NOINHERIT;"
docker exec -it postgres psql -c 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO "ro";'
