##### AWS #####
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    awscc = {
      source = "hashicorp/awscc"
    }
  }
}

provider "aws" {
  profile = var.profile_name
}

provider "awscc" {
  profile = var.profile_name
}
