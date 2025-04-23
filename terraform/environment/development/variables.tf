locals {
  // common
  aws_profile     = "sandbox"
  route53_zone_id = "Z06272247TSQ89OL8QZN"
  root_domain     = "charalarm-development.swiswiswift.com"

  // api
  api_record_name = "api"

  // resource
  resource_domain              = "resource.charalarm-development.swiswiswift.com"
  resource_bucket_name         = "resource.charalarm-development.swiswiswift.com"
  resource_acm_certificate_arn = "arn:aws:acm:us-east-1:397693451628:certificate/6f024ec6-82c4-4412-b43e-e7095dc4195e"





  // deprecated?
  api_acm_certificate_arn = "arn:aws:acm:ap-northeast-1:397693451628:certificate/766e3ddf-1e97-406f-a3e8-32aedb8c5ce6"
  application_version     = "0.0.1"
  application_bucket_name = "application.charalarm.sandbox.swiswiswift.com"
  lp_domain               = "charalarm.sandbox.swiswiswift.com"
  lp_bucket_name          = "charalarm.sandbox.swiswiswift.com"
  lp_acm_certificate_arn  = "arn:aws:acm:us-east-1:397693451628:certificate/f7fadcbe-34ce-454d-8ee6-9ccdf4dc0d9b"

  ios_voip_push_certificate_filename = "development-voip-expiration-20260408-certificate.pem"
  ios_voip_push_private_filename     = "development-voip-expiration-20260408-privatekey.pem"
  datadog_log_forwarder_arn          = "arn:aws:lambda:ap-northeast-1:397693451628:function:datadog-forwarder"
}
