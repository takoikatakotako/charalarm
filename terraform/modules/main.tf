terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.65.0"
    }
  }

  backend "s3" {
    bucket = "charalarm.terraform.state"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  profile                  = local.aws_profile
  region                   = "ap-northeast-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

module "dynamodb" {
  source = "./dynamodb"
}

module "lp" {
  source              = "./lp"
  bucket_name         = local.lp_bucket_name
  acm_certificate_arn = local.lp_acm_certificate_arn
  domain              = local.lp_domain
  zone_id             = local.route53_zone_id
}

module "resource" {
  source              = "./resource"
  bucket_name         = local.resource_bucket_name
  acm_certificate_arn = local.resource_acm_certificate_arn
  domain              = local.resource_domain
  zone_id             = local.route53_zone_id
}

module "sqs" {
  source                     = "./sqs"
  worker_lambda_function_arn = module.worker.worker_lambda_function_arn
}

module "platform_application" {
  source                         = "./platform_application"
  apple_platform_team_id         = "5RH346BQ66"
  apple_platform_bundle_id       = "com.charalarm.staging"
  ios_push_credential_file       = "AuthKey_NL6K5FR5S8.p8"
  ios_push_platform_principal    = "NL6K5FR5S8"
  ios_voip_push_certificate_file = local.ios_voip_push_certificate_filename
  ios_voip_push_private_file     = local.ios_voip_push_private_filename
}

module "web_api" {
  source                    = "./web_api"
  domain                    = local.api_domain
  route53_zone_id           = local.route53_zone_id
  acm_certificate_arn       = local.api_acm_certificate_arn
  application_version       = local.application_version
  application_bucket_name   = local.application_bucket_name
  resource_domain           = local.resource_domain
  datadog_log_forwarder_arn = local.datadog_log_forwarder_arn
}


module "batch" {
  source          = "./batch"
  resource_domain = local.resource_domain
}

module "worker" {
  source                    = "./worker"
  datadog_log_forwarder_arn = local.datadog_log_forwarder_arn
}

module "datadog" {
  source     = "./datadog"
  dd_api_key = local.dd_api_key
}

module "github" {
  source = "./github"
}
