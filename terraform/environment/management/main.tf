terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.83.1"
    }
  }

  backend "s3" {
    bucket  = "charalarm.terraform.state"
    key     = "management/terraform.tfstate"
    region  = "ap-northeast-1"
    profile = "charalarm-management"
  }
}

provider "aws" {
  profile = "charalarm-management"
  region  = "ap-northeast-1"
}


module "api_repository" {
  source = "../../modules/repository"
  name = "charalarm-api"
}

module "batch_repository" {
  source = "../../modules/repository"
  name = "charalarm-batch"
}

module "worker_repository" {
  source = "../../modules/repository"
  name = "charalarm-worker"
}

# module "github" {
#   source = "../../modules/github"
# }
