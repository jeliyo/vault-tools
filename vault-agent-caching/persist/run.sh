#!/usr/bin/env bash -x

## Put whatever vault in your path you wish to test.  If the
## persistent caching works, the diff will be empty for the db-creds.

## vault server logs in /tmp/server.log
## agent "init container" logs in /tmp/agent-init.log
## agent "sidecar container" logs in /tmp/agent-sidecar.log

./setup-postgres.sh

mkdir -p dev/config

./init.sh

./sidecar.sh

diff /tmp/db-creds-init /tmp/db-creds-sidecar

./cleanup.sh
