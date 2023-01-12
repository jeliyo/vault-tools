#!/bin/bash

# mkcert -ecdsa -cert-file certs/mysql.pem -key-file certs/mysql-key.pem localhost mysql 127.0.0.1 0.0.0.0

# cat certs/mysql.pem certs/mysql-key.pem > certs/combined.pem

# cp "$(mkcert -CAROOT)"/rootCA.pem certs/

pushd certs
./setup.sh
popd
