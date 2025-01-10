variable "domain" {
  type = string
}

variable "route53_zone_id" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "application_version" {
  type = string
}

variable "application_bucket_name" {
  type = string
}

variable "resource_domain" {
  type = string
}

variable "datadog_log_forwarder_arn" {
  type = string
}

locals {
  application_bucket_s3_url = "s3://${aws_s3_bucket.application_bucket.bucket}"
  variables = {
    "RESOURCE_BASE_URL" = "https://${var.resource_domain}"
  }
}