variable "name_prefix" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "admin_api_function_name" {
  type = string
}

variable "admin_api_function_url" {
  type = string
}

variable "basic_auth_user_ssm_parameter_name" {
  type = string
}

variable "basic_auth_password_ssm_parameter_name" {
  type = string
}
