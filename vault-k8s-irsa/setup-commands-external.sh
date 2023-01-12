
## this is intended to run locally against a remote vault (like HCP Vault)

vault secrets enable -path=internal kv-v2
vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"
vault kv get internal/database/config

vault policy write internal-app - <<EOH
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOH

vault auth enable aws
vault write -force auth/aws/config/client
ROLE_ARN=$(eksctl get iamserviceaccount --cluster tvoran-dev | grep internal-app | awk '{print $3}')
vault write auth/aws/role/dev-role-iam auth_type=iam bound_iam_principal_arn="$ROLE_ARN" policies=internal-app ttl=24h resolve_aws_unique_ids=false

