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
      resource_domain                    = "resource.charalarm.sandbox.swiswiswift.com"
      resource_bucket_name               = "resource.charalarm.sandbox.swiswiswift.com"
      resource_acm_certificate_arn       = "arn:aws:acm:us-east-1:397693451628:certificate/6f024ec6-82c4-4412-b43e-e7095dc4195e"
      ios_voip_push_certificate_filename = "development-voip-expiration-20250314-certificate.pem"
      ios_voip_push_private_filename     = "development-voip-expiration-20250314-privatekey.pem"
      datadog_log_forwarder_arn          = "arn:aws:lambda:ap-northeast-1:397693451628:function:datadog-forwarder"
    }

    staging = {
      application_version                = "0.0.1"
      aws_profile                        = "charalarm-staging"
      route53_zone_id                    = "Z1001429NNWJ0CTVGUIG"
      api_domain                         = "api.charalarm.swiswiswift.com"
      api_acm_certificate_arn            = "arn:aws:acm:ap-northeast-1:334832660826:certificate/05220010-3029-4b61-827a-fac783808a8c"
      application_bucket_name            = "application.charalarm.swiswiswift.com"
      lp_domain                          = "charalarm.swiswiswift.com"
      lp_bucket_name                     = "charalarm.swiswiswift.com"
      lp_acm_certificate_arn             = "arn:aws:acm:us-east-1:334832660826:certificate/92021af4-b3ae-4d21-96b8-fc8736b9c1e1"
      resource_domain                    = "resource.charalarm.swiswiswift.com"
      resource_bucket_name               = "resource.charalarm.swiswiswift.com"
      resource_acm_certificate_arn       = "arn:aws:acm:us-east-1:334832660826:certificate/cbd20721-8637-4079-9843-37169da6daa9"
      ios_voip_push_certificate_filename = "staging-voip-expiration-20250314-certificate.pem"
      ios_voip_push_private_filename     = "staging-voip-expiration-20250314-privatekey.pem"
      datadog_log_forwarder_arn          = "arn:aws:lambda:ap-northeast-1:334832660826:function:datadog-forwarder"
    }

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
      ios_voip_push_certificate_filename = "production-voip-expiration-20250314-certificate.pem"
      ios_voip_push_private_filename     = "production-voip-expiration-20250314-privatekey.pem"
      datadog_log_forwarder_arn          = "arn:aws:lambda:ap-northeast-1:986921280333:function:datadog-forwarder"
    }
  }

  aws_profile                        = local.config[terraform.workspace].aws_profile
  route53_zone_id                    = local.config[terraform.workspace].route53_zone_id
  api_domain                         = local.config[terraform.workspace].api_domain
  api_acm_certificate_arn            = local.config[terraform.workspace].api_acm_certificate_arn
  application_version                = local.config[terraform.workspace].application_version
  application_bucket_name            = local.config[terraform.workspace].application_bucket_name
  lp_domain                          = local.config[terraform.workspace].lp_domain
  lp_bucket_name                     = local.config[terraform.workspace].lp_bucket_name
  lp_acm_certificate_arn             = local.config[terraform.workspace].lp_acm_certificate_arn
  resource_domain                    = local.config[terraform.workspace].resource_domain
  resource_bucket_name               = local.config[terraform.workspace].resource_bucket_name
  resource_acm_certificate_arn       = local.config[terraform.workspace].resource_acm_certificate_arn
  ios_voip_push_certificate_filename = local.config[terraform.workspace].ios_voip_push_certificate_filename
  ios_voip_push_private_filename     = local.config[terraform.workspace].ios_voip_push_private_filename
  datadog_log_forwarder_arn          = local.config[terraform.workspace].datadog_log_forwarder_arn
}
