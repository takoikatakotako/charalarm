locals {

  root_domain2 = "charalarm-staging.swiswiswift.com"

  resource_domain2      = "resource.charalarm-staging.swiswiswift.com"
  resource_bucket_name2 = "resource.charalarm-staging.swiswiswift.com"

  api_record_name2 = "api"


  // deprecatec?
  aws_profile                        = "charalarm-staging"
  route53_zone_id                    = "Z1001429NNWJ0CTVGUIG"
  api_domain                         = "api.charalarm.swiswiswift.com"
  api_acm_certificate_arn            = "arn:aws:acm:ap-northeast-1:334832660826:certificate/05220010-3029-4b61-827a-fac783808a8c"
  application_version                = "0.0.1"
  application_bucket_name            = "application.charalarm.swiswiswift.com"
  lp_domain                          = "charalarm.swiswiswift.com"
  lp_bucket_name                     = "charalarm.swiswiswift.com"
  lp_acm_certificate_arn             = "arn:aws:acm:us-east-1:334832660826:certificate/92021af4-b3ae-4d21-96b8-fc8736b9c1e1"
  resource_domain                    = "resource.charalarm.swiswiswift.com"
  resource_bucket_name               = "resource.charalarm.swiswiswift.com"
  resource_acm_certificate_arn       = "arn:aws:acm:us-east-1:334832660826:certificate/cbd20721-8637-4079-9843-37169da6daa9"
  ios_voip_push_certificate_filename = "staging-voip-expiration-20260408-certificate.pem"
  ios_voip_push_private_filename     = "staging-voip-expiration-20260408-privatekey.pem"
  datadog_log_forwarder_arn          = "arn:aws:lambda:ap-northeast-1:334832660826:function:datadog-forwarder"
}
