terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.83.1"
    }
  }

  backend "s3" {
    bucket  = "charalarm.terraform.state"
    key     = "staging/terraform.tfstate"
    region  = "ap-northeast-1"
    profile = "charalarm-management"
  }
}

provider "aws" {
  profile = "charalarm-staging"
  region  = "ap-northeast-1"
}




module "dynamodb" {
  source = "../../modules/dynamodb"
}

module "lp" {
  source              = "../../modules/lp"
  bucket_name         = local.lp_bucket_name
  acm_certificate_arn = local.lp_acm_certificate_arn
  domain              = local.lp_domain
  zone_id             = local.route53_zone_id
}

module "resource" {
  source              = "../../modules/resource"
  bucket_name         = local.resource_bucket_name
  acm_certificate_arn = local.resource_acm_certificate_arn
  domain              = local.resource_domain
  zone_id             = local.route53_zone_id
}

module "sqs" {
  source                     = "../../modules/sqs"
  worker_lambda_function_arn = module.worker.worker_lambda_function_arn
}

module "platform_application" {
  source                         = "../../modules/platform_application"
  apple_platform_team_id         = "5RH346BQ66"
  apple_platform_bundle_id       = "com.charalarm.staging"
  ios_push_credential_file       = "AuthKey_NL6K5FR5S8.p8"
  ios_push_platform_principal    = "NL6K5FR5S8"
  ios_voip_push_certificate_file = local.ios_voip_push_certificate_filename
  ios_voip_push_private_file     = local.ios_voip_push_private_filename
}

module "web_api" {
  source                    = "../../modules/web_api"
  domain                    = local.api_domain
  route53_zone_id           = local.route53_zone_id
  acm_certificate_arn       = local.api_acm_certificate_arn
  application_version       = local.application_version
  application_bucket_name   = local.application_bucket_name
  resource_domain           = local.resource_domain
  datadog_log_forwarder_arn = local.datadog_log_forwarder_arn
}


module "batch" {
  source          = "../../modules/batch"
  resource_domain = local.resource_domain
}

module "worker" {
  source                    = "../../modules/worker"
  datadog_log_forwarder_arn = local.datadog_log_forwarder_arn
}

module "datadog" {
  source     = "../../modules/datadog"
  dd_api_key = local.dd_api_key
}

module "github" {
  source = "../../modules/github"
}
