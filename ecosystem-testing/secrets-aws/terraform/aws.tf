//--------------------------------------------------------------------
// Providers

provider "aws" {
  // Credentials set via env vars

  region = var.aws_region
}
