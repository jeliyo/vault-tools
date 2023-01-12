# Azure OIDC example with 200 groups #

Showing a vault oidc auth config when an azure user is a member of
more than 200 groups.

Refs:
- https://master--vault-www.netlify.app/docs/auth/jwt_oidc_providers#azure-specific-handling-configuration
- https://learn.hashicorp.com/vault/operations/oidc-auth
- https://docs.google.com/document/d/1tAmhbUdTsms7ktxdd5rugF2uaz_mn57AeCvbnTuo3iU/edit

## Steps ##

Start vault:

``` shell
vault server -dev -log-level=debug
```

Set env variables for vault, OIDC_CLIENT_ID, and OIDC_CLIENT_SECRET to
the azure app's client id and secret:

``` shell
export VAULT_ADDR='http://127.0.0.1:8200'
export OIDC_CLIENT_ID="app id"
export OIDC_CLIENT_SECRET="app secret"
```

Run part1 to setup oidc **without** azure-specific handling, and login
showing the error:

``` shell
sh ./part1.sh
```

Run part2 to reconfigure oidc **with** azure-specific handling, and
login showing the group test140 correctly mapped to a manager policy:

``` shell
sh ./part2.sh
```
