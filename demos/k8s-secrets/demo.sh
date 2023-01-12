#!/bin/bash

########################
# include the magic
########################
. demo-magic.sh

## setup
## This demo script assumes a kubernetes cluster is up and available in the
## current kubectl context. One can be created using kind: `kind create cluster`

## setup demo namespace and roles,bindings,serviceAccounts
# kubectl create namespace demo
# kubectl apply -f roles.yaml,serviceAccounts.yaml,bindings.yaml

## start an nginx container, just to have something running in the demo namespace
# kubectl run nginx --image=nginx --namespace demo

## kill any port-forward's
pkill kubectl
helm install vault hashicorp/vault -n vault -f values.yaml --create-namespace

wait

kubectl port-forward -n vault service/vault 8200:8200 1> /dev/null &
export VAULT_DEV_ROOT_TOKEN_ID="root"
export VAULT_TOKEN="root"
export VAULT_ADDR="http://127.0.0.1:8200"

## hide the evidence
clear

## enable and configure the engine
pe "vault secrets enable kubernetes"

pe "vault write -f kubernetes/config"

# existing service account
pe 'vault write kubernetes/roles/sample-app \
    service_account_name=sample-app \
    allowed_kubernetes_namespaces=demo \
    token_max_ttl=80h \
    token_default_ttl=1h'

pe "vault write kubernetes/creds/sample-app kubernetes_namespace=demo"

## existing Role
pe 'vault write kubernetes/roles/existing-role \
  kubernetes_role_name=demo-role-list-pods \
  allowed_kubernetes_namespaces=default \
  allowed_kubernetes_namespaces=demo \
  token_max_ttl=72h \
  token_default_ttl=2h'

pe "vault write kubernetes/creds/existing-role kubernetes_namespace=demo ttl=30m"

## Revoke the created leases, and clean up kubernetes objects
pe "vault lease revoke -prefix kubernetes/creds/existing-role"

## ClusterRole rules
pe 'vault write kubernetes/roles/rules \
    allowed_kubernetes_namespaces=default \
    allowed_kubernetes_namespaces=demo \
    kubernetes_role_type=ClusterRole \
    token_max_ttl=80h \
    token_default_ttl=1h \
    generated_role_rules="rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - list"'

pe 'vault write kubernetes/creds/rules \
    kubernetes_namespace=demo \
    cluster_role_binding=true'

pe 'vault write kubernetes/creds/rules \
    kubernetes_namespace=demo \
    cluster_role_binding=false'

## Revoke
pe "vault lease revoke -prefix kubernetes/creds/rules"
