data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  cloudfront_zone_id = "Z2FDTNDATAQYW2"

  # CachingDisabled (Managed Policy)
  cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

  # AllViewerExceptHostHeader (Managed Policy)
  origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
}

variable "api_lambda_function_image_uri" {
  type = string
}

variable "root_domain_name" {
  type = string
}

variable "api_record_name" {
  type = string
}

variable "root_domain_zone_id" {
  type = string
}

variable "api_cloudfront_certificate" {
  type = string
}
