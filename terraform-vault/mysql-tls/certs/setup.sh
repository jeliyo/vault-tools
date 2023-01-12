#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${DIR?}/../helper/generate.sh

cp /tmp/certs/hashicorp-ca.pem ${DIR}
cp /tmp/certs/mysql-server.pem ${DIR}
cp /tmp/certs/mysql-server-key.pem ${DIR}
cp /tmp/certs/mysql-client.pem ${DIR}
cp /tmp/certs/mysql-client-key.pem ${DIR}
cat /tmp/certs/mysql-client.pem /tmp/certs/mysql-client-key.pem > ${DIR}/combined.pem
