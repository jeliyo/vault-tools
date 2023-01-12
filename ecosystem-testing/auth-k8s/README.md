# auth-k8s

The directories here contain example setups for the kubernetes auth
backend using vault-helm and the vault-k8s injector.

The basic pattern for these examples is to do a helm install using the
values.yaml file, then run setup-vault.sh once the pods are all
running in your k8s cluster. e.g.

``` shell
helm install vault hashicorp/vault -n vault -f values.yaml --create-namespace

./setup-vault.sh

kubectl apply -f pod-payroll.yaml

# cleanup
helm delete vault -n vault
```

Do look over values.yaml and setup-vault.sh, since these were used
primarily for my own testing and debugging, and may need to be changed
for someone else to use them.
