
## setup local vault and get creds that allow for creating IRSA oidc provider in EKS

## The approach for generating creds is taken from these slides:
## https://docs.google.com/presentation/d/1irpPezc_MuqyT0botU1IYhx145UjcGLY8DAv385_ejs/edit?usp=sharing

## start vault with current doormat creds in another window
## eval $(doormat aws --account vault_team_dev)
## vault server -dev -log-level="debug" -dev-ha -dev-transactional -dev-root-token-id=root

vault secrets enable -path=aws aws
# The tvoran-eks-rsa-role has OIDC permissions
vault write aws/roles/testrole role_arns=arn:aws:iam::501359222269:role/tvoran-eks-irsa-role credential_type=assumed_role

# generate creds with OIDC provider permissions and write to local aws
# credentials profile named "irsa"
CREDS=$(vault write -format=json aws/sts/testrole ttl=1h)
aws --profile irsa configure set aws_access_key_id $(echo $CREDS | jq -r .data.access_key)
aws --profile irsa configure set aws_secret_access_key $(echo $CREDS | jq -r .data.secret_key)
aws --profile irsa configure set aws_session_token $(echo $CREDS | jq -r .data.security_token)

eksctl utils associate-iam-oidc-provider --cluster tvoran-dev --approve --profile irsa

eksctl create iamserviceaccount \
    --name internal-app \
    --namespace default \
    --cluster tvoran-dev \
    --attach-policy-arn arn:aws:iam::501359222269:policy/KMSUserPolicy \
    --approve \
    --override-existing-serviceaccounts
