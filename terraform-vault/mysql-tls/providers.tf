terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
#       version = "2.22.1"
    }
  }
}

provider "vault" {
  # Configuration options
}
