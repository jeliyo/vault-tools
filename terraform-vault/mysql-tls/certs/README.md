# TLS Example

(These are the old instructions from jason's mtls demo in vault-tools)


```bash
./run.sh
```

## Connect

In a separate terminal:

Will fail:

```bash
export VAULT_ADDR=https://localhost:8200
vault status 
vault status -ca-cert=/tmp/certs/hashicorp-ca.pem
```

Will work:

```bash
export VAULT_ADDR=https://localhost:8200
vault status \
  -ca-cert=/tmp/certs/hashicorp-ca.pem \
  -client-cert=/tmp/certs/vault-client.pem \
  -client-key=/tmp/certs/vault-client-key.pem
```
