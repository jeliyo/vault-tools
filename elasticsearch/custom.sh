#!/usr/bin/env bash
set -ex

# elastic user password
ES_PASSWORD=<password>
# directory with certs from elasticsearch
ES_CERTS=<certs dir>

## create vault role in ES
curl \
    -k -X POST \
    -H "Content-Type: application/json" \
    -d '{"cluster": ["manage_security"]}' \
    https://elastic:$ES_PASSWORD@localhost:9200/_xpack/security/role/vault

## create vault user in ES
tee $TMPDIR/data.json <<EOF
{
    "password" : "myPa55word",
    "roles" : [ "vault" ],
    "full_name" : "Hashicorp Vault",
    "metadata" : {
        "plugin_name": "Vault Plugin Database Elasticsearch",
        "plugin_url": "https://github.com/hashicorp/vault-plugin-database-elasticsearch"
    }
}
EOF

curl \
    -k -X POST \
    -H "Content-Type: application/json" \
    -d @$TMPDIR/data.json \
    https://elastic:$ES_PASSWORD@localhost:9200/_xpack/security/user/vault

vault write database/config/my-elasticsearch-database \
    plugin_name="vault-plugin-database-elasticsearch" \
    allowed_roles="internally-defined-role,externally-defined-role" \
    username=vault \
    password=myPa55word \
    url=https://localhost:9200 \
    ca_cert=$ES_CERTS/ca/ca.crt \
    client_cert=$ES_CERTS/es01/es01.crt \
    client_key=$ES_CERTS/es01/es01.key

vault write database/roles/internally-defined-role \
      db_name=my-elasticsearch-database \
      creation_statements='{"elasticsearch_role_definition": {"indices": [{"names":["*"], "privileges":["read"]}]}}' \
      default_ttl="1h" \
      max_ttl="24h"
