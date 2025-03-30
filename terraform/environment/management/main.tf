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



//////////////////////////////////////////
// Repository
//////////////////////////////////////////
module "api_repository" {
  source                 = "../../modules/repository"
  name                   = "charalarm-api"
  allow_pull_account_ids = ["039612872248"]
}

module "batch_repository" {
  source                 = "../../modules/repository"
  name                   = "charalarm-batch"
  allow_pull_account_ids = ["039612872248"]
}

module "worker_repository" {
  source                 = "../../modules/repository"
  name                   = "charalarm-worker"
  allow_pull_account_ids = ["039612872248"]
}

module "github" {
  source = "../../modules/github"
}
