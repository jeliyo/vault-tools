#!/usr/bin/env sh

vault write auth/oidc/config -<< EOH
{
  "oidc_client_id": "$OIDC_CLIENT_ID",
  "oidc_client_secret": "$OIDC_CLIENT_SECRET",
  "default_role": "reader",
  "oidc_discovery_url": "https://login.microsoftonline.com/0e3e2e88-8caf-41ca-b4da-e3b33b6c52ec/v2.0",
  "provider_config": {
    "provider": "azure"
  }
}
EOH

vault write auth/oidc/role/reader \
      user_claim="email" \
      allowed_redirect_uris="http://localhost:8200/ui/vault/auth/oidc/oidc/callback" \
      allowed_redirect_uris="http://localhost:8250/oidc/callback" \
      groups_claim="groups" \
      oidc_scopes="https://graph.microsoft.com/.default" \
      oidc_scopes="profile" \
      policies="reader"

vault login -method=oidc role="reader"
