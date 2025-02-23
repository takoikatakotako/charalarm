locals {
  config = {
    development = {
      application_version                = "0.0.1"
      aws_profile                        = "sandbox"
      route53_zone_id                    = "Z06272247TSQ89OL8QZN"
      api_domain                         = "api.charalarm.sandbox.swiswiswift.com"
      api_acm_certificate_arn            = "arn:aws:acm:ap-northeast-1:397693451628:certificate/766e3ddf-1e97-406f-a3e8-32aedb8c5ce6"
      application_bucket_name            = "application.charalarm.sandbox.swiswiswift.com"
      lp_domain                          = "charalarm.sandbox.swiswiswift.com"
      lp_bucket_name                     = "charalarm.sandbox.swiswiswift.com"
      lp_acm_certificate_arn             = "arn:aws:acm:us-east-1:397693451628:certificate/f7fadcbe-34ce-454d-8ee6-9ccdf4dc0d9b"
      ios_voip_push_certificate_filename = "development-voip-expiration-20250314-certificate.pem"
      ios_voip_push_private_filename     = "development-voip-expiration-20250314-privatekey.pem"
      datadog_log_forwarder_arn          = "arn:aws:lambda:ap-northeast-1:397693451628:function:datadog-forwarder"
    }
  }

  aws_profile     = local.config["development"].aws_profile
  route53_zone_id = local.config["development"].route53_zone_id

  root_domain = "charalarm-development.swiswiswift.com"


  resource_domain              = "resource.charalarm-development.swiswiswift.com"
  resource_bucket_name         = "resource.charalarm-development.swiswiswift.com"
  resource_acm_certificate_arn = "arn:aws:acm:us-east-1:397693451628:certificate/6f024ec6-82c4-4412-b43e-e7095dc4195e"


  api_domain              = local.config["development"].api_domain
  api_acm_certificate_arn = local.config["development"].api_acm_certificate_arn
  application_version     = local.config["development"].application_version
  application_bucket_name = local.config["development"].application_bucket_name
  lp_domain               = local.config["development"].lp_domain
  lp_bucket_name          = local.config["development"].lp_bucket_name
  lp_acm_certificate_arn  = local.config["development"].lp_acm_certificate_arn



  ios_voip_push_certificate_filename = local.config["development"].ios_voip_push_certificate_filename
  ios_voip_push_private_filename     = local.config["development"].ios_voip_push_private_filename
  datadog_log_forwarder_arn          = local.config["development"].datadog_log_forwarder_arn
}
