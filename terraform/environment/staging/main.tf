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

provider "aws" {
  alias   = "virginia"
  profile = "charalarm-staging"
  region  = "us-east-1"
}


##############################################################
# Common
##############################################################
module "root_domain" {
  source = "../../modules/domain"
  name   = local.root_domain2
}


##############################################################
# Resource
##############################################################
module "cloudfront_resource_certificate" {
  source = "../../modules/cloudfront_certificate"
  providers = {
    aws = aws.virginia
  }
  zone_id     = module.root_domain.zone_id
  domain_name = local.resource_domain2
}

module "resource2" {
  source              = "../../modules/resource"
  bucket_name         = local.resource_bucket_name2
  acm_certificate_arn = module.cloudfront_resource_certificate.certificate_arn
  domain              = local.resource_domain2
  zone_id             = module.root_domain.zone_id
}


##############################################################
# API
##############################################################
module "cloudfront_api_certificate" {
  source = "../../modules/cloudfront_certificate"
  providers = {
    aws = aws.virginia
  }
  zone_id     = module.root_domain.zone_id
  domain_name = "${local.api_record_name2}.${local.root_domain2}"
}

module "api" {
  source                        = "../../modules/api"
  api_lambda_function_image_uri = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-api:latest"
  root_domain_name              = local.root_domain2
  api_record_name               = local.api_record_name2
  api_cloudfront_certificate    = module.cloudfront_api_certificate.certificate_arn
  root_domain_zone_id           = module.root_domain.zone_id
  resource_base_url             = "https://${local.resource_domain}"
}


##############################################################
# Batch
##############################################################
module "batch2" {
  source                   = "../../modules/batch2"
  batch_function_image_uri = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-batch"
  batch_function_image_tag = "latest"
    resource_base_url             = "https://${local.resource_domain}"
}


##############################################################
# Worker
##############################################################
module "worker2" {
  source                    = "../../modules/worker2"
  worker_function_image_uri = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-worker"
  worker_function_image_tag = "latest"
}

module "sqs" {
  source                     = "../../modules/sqs"
  worker_lambda_function_arn = module.worker2.worker_lambda_function_arn
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


##############################################################
# Database
##############################################################
module "dynamodb" {
  source = "../../modules/dynamodb"
}


##############################################################
# Deprecated
##############################################################
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


module "resource" {
  source              = "../../modules/resource"
  bucket_name         = local.resource_bucket_name
  acm_certificate_arn = local.resource_acm_certificate_arn
  domain              = local.resource_domain
  zone_id             = local.route53_zone_id
}


# module "batch" {
#   source          = "../../modules/batch"
#   resource_domain = local.resource_domain
# }


# module "worker" {
#   source                    = "../../modules/worker"
#   datadog_log_forwarder_arn = local.datadog_log_forwarder_arn
# }


module "datadog" {
  source     = "../../modules/datadog"
  dd_api_key = local.dd_api_key
}
