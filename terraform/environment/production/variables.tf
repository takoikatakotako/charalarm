locals {
  config = {
    production = {
      application_version                = "0.0.1"
      aws_profile                        = "charalarm-production"
      route53_zone_id                    = "Z00844703N1I59JY0GXTS"
      api_domain                         = "api2.charalarm.com"
      api_acm_certificate_arn            = "arn:aws:acm:ap-northeast-1:986921280333:certificate/c7aa8b9b-da17-480d-94da-11d1ac33dafd"
      application_bucket_name            = "application.charalarm.com"
      lp_domain                          = "charalarm.com"
      lp_bucket_name                     = "charalarm.com"
      lp_acm_certificate_arn             = "arn:aws:acm:us-east-1:986921280333:certificate/3aa7855f-d3ae-4d26-a974-830bc58766eb"
      resource_domain                    = "resource.charalarm.com"
      resource_bucket_name               = "resource.charalarm.com"
      resource_acm_certificate_arn       = "arn:aws:acm:us-east-1:986921280333:certificate/c62fff84-8e07-495a-8fa9-359372471c37"
      datadog_log_forwarder_arn          = "arn:aws:lambda:ap-northeast-1:986921280333:function:datadog-forwarder"
    }
  }

  aws_profile                        = local.config["production"].aws_profile
  route53_zone_id                    = local.config["production"].route53_zone_id
  api_domain                         = local.config["production"].api_domain
  api_acm_certificate_arn            = local.config["production"].api_acm_certificate_arn
  application_version                = local.config["production"].application_version
  application_bucket_name            = local.config["production"].application_bucket_name
  lp_domain                          = local.config["production"].lp_domain
  lp_bucket_name                     = local.config["production"].lp_bucket_name
  lp_acm_certificate_arn             = local.config["production"].lp_acm_certificate_arn
  resource_domain                    = local.config["production"].resource_domain
  resource_bucket_name               = local.config["production"].resource_bucket_name
  resource_acm_certificate_arn       = local.config["production"].resource_acm_certificate_arn
  ios_voip_push_certificate_filename = "production-voip-expiration-20260408-certificate.pem"
  ios_voip_push_private_filename     = "production-voip-expiration-20260408-privatekey.pem"
  datadog_log_forwarder_arn          = local.config["production"].datadog_log_forwarder_arn
}
