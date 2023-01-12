#!/usr/bin/env bash -x

kubectl delete -f pod-payroll.yml
eksctl delete iamserviceaccount --name internal-app --namespace default --cluster tvoran-dev
OIDCURL=$(aws eks describe-cluster --region us-west-2 --name tvoran-dev --output json | jq -r .cluster.identity.oidc.issuer | sed -e "s*https://**")
aws iam delete-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::501359222269:oidc-provider/$OIDCURL --profile=irsa --region us-west-2

eksctl delete cluster --region=us-west-2 --name=tvoran-dev
