

##############################################################
# Common
##############################################################
module "root_domain" {
  source = "../../modules/domain"
  name   = local.root_domain
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
  domain_name = local.resource_domain
}

module "resource" {
  source              = "../../modules/resource"
  bucket_name         = local.resource_bucket_name
  acm_certificate_arn = module.cloudfront_resource_certificate.certificate_arn
  domain              = local.resource_domain
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
  domain_name = "${local.api_record_name}.${local.root_domain}"
}

module "api" {
  source                        = "../../modules/api"
  api_lambda_function_image_uri = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-api"
  api_lambda_function_image_tag = "992849240ea04acbecc2d8f4f682017b6eb0418b"
  root_domain_name              = local.root_domain
  api_record_name               = local.api_record_name
  api_cloudfront_certificate    = module.cloudfront_api_certificate.certificate_arn
  root_domain_zone_id           = module.root_domain.zone_id
  resource_base_url             = "https://${local.resource_domain}"

  openai_api_key_ssm_parameter_name = "/charalarm/dev/openai-api-key"
  # 5.0.0 の会話は Vertex AI の Gemini で検証する（staging / production は検証後に切り替える）。
  # 認証は TTS と同じ Workload Identity 連携
  llm_provider = "gemini"
  llm_model    = "gemini-3.1-flash-lite"

  # Gemini TTS は sandbox の Vertex AI を使う (gcp-iac の terraform/sandbox/charalarm.tf)
  gcp_project           = "sandbox-492513"
  gcp_credential_config = local.gcp_credential_config
}


##############################################################
# Batch
##############################################################
module "batch" {
  source                   = "../../modules/batch2"
  batch_function_image_uri = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-batch"
  batch_function_image_tag = "ffe24e8fbfea805d4f0b64d28765a909edb7654c"
  resource_base_url        = "https://${local.resource_domain}"
}


##############################################################
# Worker
##############################################################
module "worker" {
  source                    = "../../modules/worker2"
  worker_function_image_uri = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-worker"
  worker_function_image_tag = "251a4fadeba1a2543514fd766945cf4ef03ced7d"
  resource_base_url         = "https://${local.resource_domain}"
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


##############################################################
# Database
##############################################################
module "dynamodb" {
  source = "../../modules/dynamodb"
}





##############################################################
# Vertex AI (Gemini TTS) の credential config
##############################################################
# API Lambda の実行ロールの AWS 認証情報を、Workload Identity 連携で
# GCP の charalarm-tts SA のトークンに交換する。秘密値は含まない。
locals {
  gcp_credential_config = jsonencode({
    type                              = "external_account"
    audience                          = "//iam.googleapis.com/projects/870183222406/locations/global/workloadIdentityPools/charalarm-aws/providers/development"
    subject_token_type                = "urn:ietf:params:aws:token-type:aws4_request"
    token_url                         = "https://sts.googleapis.com/v1/token"
    service_account_impersonation_url = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/charalarm-tts@sandbox-492513.iam.gserviceaccount.com:generateAccessToken"
    credential_source = {
      environment_id                 = "aws1"
      regional_cred_verification_url = "https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15"
    }
  })
}
