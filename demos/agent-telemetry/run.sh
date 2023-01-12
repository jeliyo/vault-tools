#!/usr/bin/env bash -x

## Put whatever vault in your path you wish to test.

## vault server logs in /tmp/server.log
## agent logs in /tmp/agent.log

./setup-postgres.sh

mkdir -p dev/config

./agent.sh

## Now start up prometheus and grafana
./prometheus_grafana.sh


./cleanup.sh
