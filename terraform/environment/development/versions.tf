terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.68.0"
    }
  }

  backend "s3" {
    bucket  = "charalarm.terraform.state"
    key     = "development/terraform.tfstate"
    region  = "ap-northeast-1"
    profile = "charalarm-management-sso"
  }
}
