# secrets/aws acceptance tests

Acceptance tests require a Vault Enterprise license to be provided
and the following tools to be installed:
- [Docker](https://docs.docker.com/get-docker/)
- [jq](https://stedolan.github.io/jq/)
- [bats](https://bats-core.readthedocs.io/en/stable)

``` shell
bats secrets-aws.bats
```

These test exercise the different credential_type's for the AWS secrets backend.
They all read AWS credentials from the environment. They may all be executed at
once, but since each requires different permissions to run, it can be useful to
run them individually as well.

The examples below are specific to HashiCorp's doormat setup.

## iam_user

Assume the vaultAwsDev role (as documented
[here](https://hashicorp.atlassian.net/l/c/nHARerA9)) and run the test.

``` shell
get_vault_aws

bats -f iam_user secrets-aws.bats
```

## assumed_role

``` shell
eval $(doormat aws --account vault_team_dev)

bats -f assumed_role secrets-aws.bats
```

## federation_token

This credential_type needs static AWS creds, so one way is to create a user as outlined below:

Setup:

``` shell
# assume vaultAwsDevRole
get_vault_aws

# create a user
aws iam create-user --user-name vault-test-fed
aws iam attach-user-policy --user-name vault-test-fed --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess
aws iam put-user-policy --user-name vault-test-fed --policy-name inline --policy-document '{        
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "selfIAM", 
            "Effect": "Allow",
            "Action": "iam:*",
            "Resource": "arn:aws:iam::501359222269:user/vault-test-fed"
        },
        {
            "Sid": "getFed",  
            "Effect": "Allow",
            "Action": "sts:GetFederationToken",
            "Resource": "*"
        }
    ]
}'

# get the fed user creds and set in your environment
fedRootCreds=$(aws iam create-access-key --user vault-test-fed)
export AWS_ACCESS_KEY_ID=$(jq -r .AccessKey.AccessKeyId <<<$fedRootCreds)
export AWS_SECRET_ACCESS_KEY=$(jq -r .AccessKey.SecretAccessKey <<<$fedRootCreds)
unset AWS_SESSION_TOKEN

```

Run the test:

``` shell
bats -f federation_token secrets-aws.bats
```

Cleanup:

``` shell
# assume vaultAwsDevRole
get_vault_aws

# delete the aws user
aws iam delete-user-policy --user-name vault-test-fed --policy-name inline
aws iam detach-user-policy --user-name vault-test-fed --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess
access_keys=$(aws iam list-access-keys --user-name vault-test-fed)
aws iam delete-access-key --user-name vault-test-fed --access-key-id $(jq -r '.AccessKeyMetadata[0].AccessKeyId' <<<$access_keys)
aws iam delete-user --user-name vault-test-fed