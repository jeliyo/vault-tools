#!/usr/bin/env sh

## this is the object id of group test140 in azure
MGR_GROUP="1783062b-46e0-4d49-9142-84c73776a7fd"

vault auth enable oidc || true

vault policy write manager manager.hcl
vault policy write reader reader.hcl

vault write auth/oidc/config -<<EOH
{
  "oidc_client_id": "$OIDC_CLIENT_ID",
  "oidc_client_secret": "$OIDC_CLIENT_SECRET",
  "default_role": "reader",
  "oidc_discovery_url": "https://login.microsoftonline.com/0e3e2e88-8caf-41ca-b4da-e3b33b6c52ec/v2.0"
}
EOH

vault write auth/oidc/role/reader \
      user_claim="email" \
      allowed_redirect_uris="http://localhost:8200/ui/vault/auth/oidc/oidc/callback" \
      allowed_redirect_uris="http://localhost:8250/oidc/callback" \
      groups_claim="groups" \
      oidc_scopes="https://graph.microsoft.com/.default" \
      policies="reader"

## Grant access to the manager policy in vault to members of group
## test140 in azure

vault write identity/group name="manager" type="external" \
      policies="manager" \
      metadata=responsibility="Manage K/V Secrets"


GROUP_ID=$(vault write -format json identity/group name="manager" type="external" \
           policies="manager" \
           metadata=responsibility="Manage K/V Secrets" | jq -r .data.id)

ACCESSOR=$(vault auth list -format=json \
           | jq -r '."oidc/".accessor')

vault write identity/group-alias name="$MGR_GROUP" \
      mount_accessor="$ACCESSOR" \
      canonical_id="$GROUP_ID"

vault login -method=oidc role="reader"
