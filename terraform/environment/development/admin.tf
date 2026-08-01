##############################################################
# Admin API (Lambda)
##############################################################
module "admin_api" {
  source                           = "../../modules/admin_api"
  function_name                    = "${local.prefix}-admin-api"
  image_uri                        = "448049807848.dkr.ecr.ap-northeast-1.amazonaws.com/charalarm-admin-api"
  image_tag                        = "latest"
  origin_secret_ssm_parameter_name = "/charalarm/dev/admin/basic-auth-password"
}


##############################################################
# Admin Frontend (S3 + CloudFront)
##############################################################
module "cloudfront_admin_certificate" {
  source = "../../modules/cloudfront_certificate"
  providers = {
    aws = aws.virginia
  }
  zone_id     = module.root_domain.zone_id
  domain_name = "admin.${local.root_domain}"
}

module "admin_frontend" {
  source                                 = "../../modules/admin_frontend"
  name_prefix                            = local.prefix
  bucket_name                            = "${local.prefix}-admin"
  domain                                 = "admin.${local.root_domain}"
  zone_id                                = module.root_domain.zone_id
  acm_certificate_arn                    = module.cloudfront_admin_certificate.certificate_arn
  admin_api_function_name                = module.admin_api.function_name
  admin_api_function_url                 = module.admin_api.function_url
  basic_auth_user_ssm_parameter_name     = "/charalarm/dev/admin/basic-auth-user"
  basic_auth_password_ssm_parameter_name = "/charalarm/dev/admin/basic-auth-password"
}
