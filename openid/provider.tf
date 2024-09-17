provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "cloudsec-terraform-project"
    key    = "openid/terraform.tfstate"
    region = "us-east-2"
  }
}
