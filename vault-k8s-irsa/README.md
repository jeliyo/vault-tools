# vault-k8s irsa

Start with an EKS cluster (mine is named `tvoran-dev`) and an external vault
(like on HCP).

Set your external vault address in values-public.yaml, and install the injector:

```console
helm install vault hashicorp/vault -f values-public.yaml
```

Refresh your doormat creds, e.g.

```console
doormat aws -r arn:aws:iam::501359222269:role/vault_team_dev-developer -m -p default
```

Then run `setup-irsa-creds-k8s.sh` (take a look inside for some extra local
vault setup).

Then run `setup-commands-external.sh` against your HCP Vault.

Now submit `pod-payroll.yaml` and see the creds in /vault/secrets/.


Note: `cleanup.sh` has teardown commands for everything (including the EKS cluster).
