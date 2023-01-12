# AWS region
variable "aws_region" {
  default = "us-west-2"
}

# All resources will be named with this
variable "environment_name" {
  default = "vault-aws-secrets-test"
}
