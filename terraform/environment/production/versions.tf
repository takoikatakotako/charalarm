terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.83.1"
    }
  }

  backend "s3" {
    bucket  = "charalarm.terraform.state"
    key     = "production/terraform.tfstate"
    region  = "ap-northeast-1"
    profile = "charalarm-management-sso"
  }
}
