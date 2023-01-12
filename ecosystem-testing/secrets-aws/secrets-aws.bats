#!/usr/bin/env bats

# load _helpers

# Set env
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_LICENSE=${VAULT_LICENSE_CI?}
VAULT_IMAGE="${VAULT_IMAGE:-hashicorp/vault-enterprise:latest}"
SETUP_TEARDOWN_OUTFILE=/tmp/bats-test.log
NAMESPACE=${VAULT_NAMESPACE_CI:-test-namespace}
export VAULT_TOKEN=root


# Run vault in docker
setup_docker() {
    docker pull ${VAULT_IMAGE?}

    docker run \
           --rm \
           --name=vault \
           --hostname=vault \
           -p 8200:8200 \
           -e VAULT_DEV_ROOT_TOKEN_ID=root \
           -e VAULT_ADDR \
           -e VAULT_DEV_LISTEN_ADDRESS="0.0.0.0:8200" \
           -e VAULT_LICENSE \
           -e AWS_ACCESS_KEY_ID \
           -e AWS_SECRET_ACCESS_KEY \
           -e AWS_SESSION_TOKEN \
           -e AWS_SESSION_EXPIRATION \
           --privileged \
           --detach ${VAULT_IMAGE?}

    # TODO: Replace with a check
    sleep 5
}

setup_vault() {
    unset VAULT_NAMESPACE
    VAULT_TOKEN='root'
    vault login ${VAULT_TOKEN?}
    vault namespace create ${NAMESPACE?}
    export VAULT_NAMESPACE=${NAMESPACE?}

    vault secrets enable -version=2 -path=kvv2 kv
    vault secrets enable -path=aws aws
}

setup() {
    { # Braces used to redirect all setup logs.
        # 1. Setup docker
        setup_docker

        # 2. Configure Vault
        setup_vault

    } > $SETUP_TEARDOWN_OUTFILE
}

teardown() {
    if [[ -n $SKIP_TEARDOWN ]]; then
        echo "Skipping teardown"
        return
    fi

    { # Braces used to redirect all teardown logs.
    export VAULT_NAMESPACE=${NAMESPACE?}
    vault secrets disable kvv2

    vault lease revoke -prefix aws/sts/
    vault lease revoke -prefix aws/creds/
    sleep 5
    sts_count=$(vault list -format=json sys/leases/lookup/aws/sts | jq '. | length')
    [[ $sts_leases -eq 0 ]]
    creds_count=$(vault list -format=json sys/leases/lookup/aws/creds | jq '. | length')
    [[ $creds_count -eq 0 ]]
    vault secrets disable aws
    # If the test failed, print some debug output
    if [[ "$BATS_ERROR_STATUS" -ne 0 ]]; then
        docker logs vault
    fi

    # Teardown Vault configuration.
    docker rm vault --force
    } > $SETUP_TEARDOWN_OUTFILE
}

@test "AWS Secrets - credential_type=iam_user" {
    # The aws secrets config endpoint doesn't support setting a
    # session token, but a running vault server will pick it up from
    # an environment variable, so we have to start vault with that env
    # variable set, so get_vault_aws() assumes the vaultAwsDevRole
    # that can create users, and sets those AWS creds in the env for
    # vault server to pick up.
    # get_vault_aws

    # setup_docker
    # setup_vault

    root_arn=$(aws sts get-caller-identity | jq -r .Arn)

    vault write aws/config/root \
        region=us-west-2
        # access_key=${AWS_ACCESS_KEY_ID?} \
        # secret_key=${AWS_SECRET_ACCESS_KEY?}
    vault write aws/roles/iam_user-role \
        policy_arns=arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess \
        credential_type=iam_user

    # rotate root - only works with static creds set on aws/config/root
    if [ -z ${AWS_SESSION_TOKEN} ]; then
        vault write -force aws/config/rotate-root
    fi

    run vault read -format=json aws/creds/iam_user-role
    CREDS=$output

    lease_id="$(jq -r '.lease_id' <<<$CREDS)"
    [ ! -z "${lease_id}" ]

    export AWS_ACCESS_KEY_ID="$(jq -r '.data.access_key' <<<$CREDS)"
    export AWS_SECRET_ACCESS_KEY="$(jq -r '.data.secret_key' <<<$CREDS)"
    export AWS_SESSION_TOKEN=""
    sleep 10  # Wait for IAM User eventual consistency

    # The aws cli commands use PAGER to display responses
    export PAGER=cat
    aws sts get-caller-identity
    creds_arn=$(jq -r .Arn <<<$output)
    [[ ${creds_arn} != ${root_arn} ]]

    aws ec2 describe-regions --region us-west-2

    vault lease revoke $lease_id
}

@test "AWS Secrets - credential_type=assumed_role" {

    root_arn=$(aws sts get-caller-identity | jq -r .Arn)

    vault write aws/roles/test-assumed_role \
        role_arns=arn:aws:iam::501359222269:role/ecosystem-test-assume-role \
        credential_type=assumed_role

    run vault write -format=json aws/sts/test-assumed_role ttl=15m
    creds=$output

    lease_id=$(echo $creds | jq -r '.lease_id')
    [[ ! -z ${lease_id} ]]
    access_key=$(echo $creds | jq -r '.data.access_key')
    [[ ! -z ${access_key} ]]
    secret_key=$(echo $creds | jq -r '.data.secret_key')
    [[ ! -z ${secret_key} ]]
    security_token=$(echo $creds | jq -r '.data.security_token')
    [[ ! -z ${security_token} ]]

    # Set the assumed_role creds in the env to test them
    export AWS_ACCESS_KEY_ID=$access_key
    export AWS_SECRET_ACCESS_KEY=$secret_key
    export AWS_SESSION_TOKEN=$security_token
    export PAGER=cat
    run aws sts get-caller-identity
    creds_arn=$(jq -r .Arn <<<$output)
    [[ ${creds_arn} != ${root_arn} ]]
    aws ec2 describe-regions --region us-west-2

    vault lease revoke $lease_id
}

@test "AWS Secrets - credential_type=federation_token" {

    root_arn=$(aws sts get-caller-identity | jq -r .Arn)

    vault write aws/config/root \
        access_key=${AWS_ACCESS_KEY_ID?} \
        secret_key=${AWS_SECRET_ACCESS_KEY?} \
        region=us-west-2

    vault write aws/roles/test-federation_token \
        policy_arns=arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess \
        credential_type=federation_token

    vault write -force aws/config/rotate-root

    # wait for AWS consistency
    sleep 5

    run vault write -format=json aws/sts/test-federation_token ttl=15m
    creds=$output

    lease_id=$(echo $creds | jq -r '.lease_id')
    [[ ! -z ${lease_id} ]]
    access_key=$(echo $creds | jq -r '.data.access_key')
    [[ ! -z ${access_key} ]]
    secret_key=$(echo $creds | jq -r '.data.secret_key')
    [[ ! -z ${secret_key} ]]
    security_token=$(echo $creds | jq -r '.data.security_token')
    [[ ! -z ${security_token} ]]

    # Set the assumed_role creds in the env to test them
    export AWS_ACCESS_KEY_ID=$access_key
    export AWS_SECRET_ACCESS_KEY=$secret_key
    export AWS_SESSION_TOKEN=$security_token
    export PAGER=cat
    run aws sts get-caller-identity
    creds_arn=$(jq -r .Arn <<<$output)
    [[ ${creds_arn} != ${root_arn} ]]

    aws ec2 describe-regions --region us-west-2

    vault lease revoke $lease_id

}
