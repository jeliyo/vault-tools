# Testing SSH alternate signing algo fix

https://hashicorp.atlassian.net/browse/VAULT-445

Run ./gen-certs.sh once, then ./setup-ssh-secrets.sh to test a vault
version. If the last command generates a key without an error, the fix
worked.
