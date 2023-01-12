#!/bin/bash
set -aex

echo "rutabaga" > /tmp/serviceaccount

cd dev

cat > config/agent-load.hcl -<<EOF
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
    keep_after_import = true
    exit_on_error = true
    service_account_token_file = "/tmp/serviceaccount"
  }
  use_auto_auth_token = true
}

exit_after_auth = false

template {
  destination = "/tmp/db-creds-sidecar"
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
vault agent -log-level=trace -config config/agent-load.hcl > /tmp/agent-sidecar.log 2>&1 &
sleep 5s

VAULT_AGENT_ADDR=http://127.0.0.1:8007

# secretID=$(vault write -format json -f auth/approle/role/role1/secret-id | jq -r '.data.secret_id')
# roleID=$(vault read -format json auth/approle/role/role1/role-id | jq -r '.data.role_id')
secretID=$(cat .secretID)
roleID=$(cat .roleID)
vault write auth/approle/login role_id=$roleID secret_id=$secretID

# Login again with same credentials
vault write auth/approle/login role_id=$roleID secret_id=$secretID

# Login again with same credentials
## CLIENT_TOKEN=$(vault write -format=json auth/approle/login role_id=$roleID secret_id=$secretID | jq -r .auth.client_token)
CLIENT_TOKEN=$(cat /tmp/approle-token)


# read db creds again?
VAULT_TOKEN=$CLIENT_TOKEN vault read database/creds/readonly
