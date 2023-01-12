#!/bin/bash
set -aex

# Kill existing processes
pkill -9 vault || true
sleep 5s

# rm old bolt file
rm -f /tmp/vault-agent-cache.db

export VAULT_DEV_ROOT_TOKEN_ID="root"
export VAULT_TOKEN="root"
export VAULT_ADDR="http://127.0.0.1:8200"

# Start the vault server
vault server -dev -log-level="debug" -dev-ha -dev-transactional -dev-root-token-id=root > /tmp/server.log 2>&1 &
# vault server -dev -dev-root-token-id root -log-level=debug -dev-plugin-dir=plugin-dir > /tmp/server.log 2>&1 &
sleep 5s

tee secret-policy.hcl <<EOF
path "secret/kv/*" {
    capabilities = [ "read", "update", "create" ]
}
EOF
vault policy write all-kv secret-policy.hcl

tee db-policy.hcl <<EOF
path "database/*" {
    capabilities = [ "read", "update", "create" ]
}
EOF
vault policy write db db-policy.hcl


# Enable the approle auth method, configure a role and generate a secret ID
vault auth enable approle
vault write auth/approle/role/role1 bind_secret_id=true token_policies=demopolicy,all-kv,db token_ttl=5m token_max_ttl=1h
secretID=$(vault write -format json -f auth/approle/role/role1/secret-id | jq -r '.data.secret_id')
roleID=$(vault read -format json auth/approle/role/role1/role-id | jq -r '.data.role_id')

# Setup postgres stuff
vault secrets enable database
vault write database/config/postgresql \
      plugin_name=postgresql-database-plugin \
      connection_url="postgresql://{{username}}:{{password}}@localhost:5432/postgres?sslmode=disable" \
      allowed_roles=readonly \
      username="root" \
      password="rootpassword"
tee readonly.sql <<EOF
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;
GRANT ro TO "{{name}}";
EOF
vault write database/roles/readonly \
      db_name=postgresql \
      creation_statements=@readonly.sql \
      default_ttl=1m \
      max_ttl=1h


# Save the secret ID and the role ID in files that are picked up by the agent
echo -n $secretID > /tmp/secretIDFile
echo -n $roleID > /tmp/roleIDFile

echo "rutabaga" > /tmp/serviceaccount

cd dev

echo -n $secretID > .secretID
echo -n $roleID > .roleID

cat > config/agent.hcl -<<EOF
auto_auth {
    method {
        type = "approle"
        config = {
            role_id_file_path = "/tmp/roleIDFile"
            secret_id_file_path = "/tmp/secretIDFile"
        }
    }

    sink {
        type = "file"
        config = {
            path = "/tmp/approle-token"
        }
    }
}

vault {
  address = "http://127.0.0.1:8200"
}

cache {
  persist "kubernetes" {
    path = "/tmp"
    service_account_token_file = "/tmp/serviceaccount"
  }
  use_auto_auth_token = true
}

exit_after_auth = true

template {
  destination = "/tmp/db-creds-init"
  contents = "{{- with secret \"database/creds/readonly\" -}}\npostgres://{{ .Data.username }}:{{ .Data.password }}@postgres.postgres.svc:5432/wizard?sslmode=disable\n{{- end }}\n"
  left_delimiter = "{{",
  right_delimiter = "}}"
}

listener "tcp" {
  address = "127.0.0.1:8007"
  tls_disable = true
}
EOF

# Start the agent
vault agent -log-level=trace -config config/agent.hcl > /tmp/agent-init.log 2>&1
sleep 5s

echo -n $secretID > /tmp/secretIDFile
