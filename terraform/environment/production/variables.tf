locals {

  root_domain = "charalarm.com"

  resource_domain2      = "resource2.charalarm.com"
  resource_bucket_name2 = "resource2.charalarm.com"

  // API
  api_record_name2 = "api3"


  route53_zone_id                    = "Z00844703N1I59JY0GXTS"
  lp_domain                          = "charalarm.com"
  lp_bucket_name                     = "charalarm.com"
  lp_acm_certificate_arn             = "arn:aws:acm:us-east-1:986921280333:certificate/3aa7855f-d3ae-4d26-a974-830bc58766eb"
  ios_voip_push_certificate_filename = "production-voip-expiration-20270507-certificate.pem"
  ios_voip_push_private_filename     = "production-voip-expiration-20270507-privatekey.pem"
}
