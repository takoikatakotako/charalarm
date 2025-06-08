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
  source = "../../modules/repository"
  name   = "charalarm-api"
  allow_pull_account_ids = [
    local.development_account_id,
    local.staging_account_id,
    local.production_account_id
  ]
}

module "batch_repository" {
  source = "../../modules/repository"
  name   = "charalarm-batch"
  allow_pull_account_ids = [
    local.development_account_id,
    local.staging_account_id,
    local.production_account_id
  ]
}

module "worker_repository" {
  source = "../../modules/repository"
  name   = "charalarm-worker"
  allow_pull_account_ids = [
    local.development_account_id,
    local.staging_account_id,
    local.production_account_id
  ]
}

module "github" {
  source = "../../modules/github"
}
