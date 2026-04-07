locals {

  root_domain2 = "charalarm-staging.swiswiswift.com"

  resource_domain2      = "resource.charalarm-staging.swiswiswift.com"
  resource_bucket_name2 = "resource.charalarm-staging.swiswiswift.com"

  api_record_name2 = "api"


  ios_voip_push_certificate_filename = "staging-voip-expiration-20270507-certificate.pem"
  ios_voip_push_private_filename     = "staging-voip-expiration-20270507-privatekey.pem"
  datadog_log_forwarder_arn          = "arn:aws:lambda:ap-northeast-1:334832660826:function:datadog-forwarder"
}
