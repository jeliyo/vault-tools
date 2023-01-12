#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ORG='hashicorp'
NAME='mysql'

if [[ -d /tmp/certs ]]
then
    mkdir -p /tmp/certs
fi

mkdir -p /tmp/certs

cfssl gencert -initca ca-csr.json | cfssljson -bare /tmp/certs/${ORG?}-ca

cfssl gencert \
  -ca=/tmp/certs/${ORG?}-ca.pem \
  -ca-key=/tmp/certs/${ORG?}-ca-key.pem \
  -config=ca-config.json \
  -profile=server \
   server-csr.json | cfssljson -bare /tmp/certs/${NAME?}-server

cfssl gencert \
  -ca=/tmp/certs/${ORG?}-ca.pem \
  -ca-key=/tmp/certs/${ORG?}-ca-key.pem  \
  -config=ca-config.json \
  -profile=client \
   client-csr.json | cfssljson -bare /tmp/certs/${NAME?}-client
