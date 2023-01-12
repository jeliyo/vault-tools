#!/bin/bash

kubectl cp vault-commands.sh vault/vault-0:/tmp/
kubectl -n vault exec vault-0 -- sh -c 'sh /tmp/vault-commands.sh'

kubectl apply -f service-account-internal-app.yml

