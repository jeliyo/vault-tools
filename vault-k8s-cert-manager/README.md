# vault-k8s and cert-manager

Scripts to demo using cert-manager to manage the certs for the vault-k8s
mutating webhook service, to enable the use of multiple replicas.

(For this demo a local kind cluster was used.)

    kind create cluster

Install cert-manager:

    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \                        
        --set installCRDs=true

Setup self-signed CA:

    kubectl apply -n vault -f ca-issuer.yaml

Setup the injector cert:

    kubectl -n vault apply -f injector-certificate.yaml

Install vault-k8s configured to use the Certificate that was issued:

    export CA_BUNDLE=$(kubectl -n vault get secrets injector-tls -o json | jq -r '.data."ca.crt"')

    helm install vault hashicorp/vault \
        --namespace=vault \
        --set injector.replicas=2 \
        --set injector.leaderElector.enabled=false \
        --set injector.certs.secretName=injector-tls \
        --set injector.certs.caBundle=${CA_BUNDLE?} \
        --set injector.affinity=null --set server.dev.enabled=true  # these are for demo purposes

Submit some test jobs, and watch the injector replica logs for any failures:

    stern -l app.kubernetes.io/name=vault-agent-injector -n vault

    ./vault-setup.sh
    ./submit-jobs.sh
