terraform {
  required_version = ">= 1.10, < 2.0"

  backend "s3" {
    bucket       = "waliu-ticket-terraform-state-734754909634"
    key          = "support-ticket/dev/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}