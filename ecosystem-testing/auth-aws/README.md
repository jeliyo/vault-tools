# auth-secrets

Setup and steps to exercise Vault's AWS auth backend. Setup and terraform was
condensed and modified from the [Vault Agent with AWS learn
guide](https://learn.hashicorp.com/tutorials/vault/agent-aws?in=vault/auth-methods).

```shell
eval $(doormat aws --account vault_team_dev)

# set default overrides (ssh key, vault binary, etc.)
cp terraform.tfvars.example terraform.tfvars

# Set the vault license env var
export TF_VAR_vault_license=<vault license contents>

terraform init
terraform apply
```

ssh into the server instance (watch /var/log/syslog to see when the setup is
finished, then login again)

``` shell
root_token=$(vault operator init -format=json -n 1 -t 1 | jq -r .root_token)
vault login $root_token
./aws_auth.sh
```

## Test iam method on the instance

``` shell
export VAULT_NAMESPACE=test-namespace
iam_token=$(vault login -method=aws role=dev-role-iam -format=json | jq -r .auth.client_token)

curl --header "X-Vault-Token: $iam_token" $VAULT_ADDR/v1/test-namespace/secret/myapp/config | jq
```

## Test ec2 method on the instance

```shell
export VAULT_NAMESPACE=test-namespace

ec2_token=$(vault write -format=json auth/ec2/login role=dev-role-ec2 pkcs7=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7 | tr -d '\n') nonce=5defbf9e-a8f9-3063-bdfc-54b7a42a1f95 | jq -r .auth.client_token)

curl --header "X-Vault-Token: $ec2_token" $VAULT_ADDR/v1/test-namespace/secret/myapp/config | jq
```

## Run acceptance tests for auth method on the instance

Note: these tests require more memory than the default t2.micro. Last tested on
an m5.large.

``` shell

curl -sSL https://git.io/g-install | sh -s
sudo apt install make gcc

git clone https://github.com/hashicorp/vault
cd vault/
git checkout release/1.9.x

source ~/.bashrc
make testacc TEST=./builtin/logical/aws TESTARGS="-run=TestBackend -count 1"

```

Then go clean up any leftover IAM users if the tests failed.
(You'll probably have to use the `aws` cli on the ec2 instance).

## Bonus: run acceptance tests for AWS secrets backend on the instance

``` shell
iam_role_name=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)
creds=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${iam_role_name})
export TEST_ACCESS_KEY_ID=$(echo $creds | jq -r .AccessKeyId)
export TEST_AWS_SECRET_ACCESS_KEY=$(echo $creds | jq -r .SecretAccessKey)
export TEST_AWS_ACCESS_KEY_ID=$(echo $creds | jq -r .AccessKeyId)
export TEST_AWS_SECURITY_TOKEN=$(echo $creds | jq -r .Token)
export TEST_AWS_SESSION_TOKEN=$(echo $creds | jq -r .Token)

export TEST_AWS_EC2_PKCS7=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/pkcs7)
export TEST_AWS_EC2_IDENTITY_DOCUMENT=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | base64 -w 0)
export TEST_AWS_EC2_IDENTITY_DOCUMENT_SIG=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/signature | tr -d '\n')
export TEST_AWS_EC2_AMI_ID=$(curl -s http://169.254.169.254/latest/meta-data/ami-id)
export TEST_AWS_EC2_IAM_ROLE_ARN=$(aws iam get-role --role-name $(curl -q http://169.254.169.254/latest/meta-data/iam/security-credentials/ -S -s) --query Role.Arn --output text)
export TEST_AWS_EC2_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

make testacc TEST=./builtin/credential/aws TESTARGS="-run=TestBackendAcc -count 1"

```
