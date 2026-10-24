variable "apple_platform_team_id" {
  type = string
}

variable "apple_platform_bundle_id" {
  type = string
}

variable "ios_push_platform_principal" {
  type = string
}

# APNs の鍵と証明書を置いた SSM パラメータの先頭（例: /charalarm/dev/apns）。
# CI からも plan / apply できるよう、手元のファイルではなく SSM から読む（#311）。
# 置き方は terraform/scripts/put-apns-credentials.sh を参照。
variable "apns_ssm_parameter_prefix" {
  type = string
}

data "aws_ssm_parameter" "ios_push_auth_key" {
  name = "${var.apns_ssm_parameter_prefix}/push-auth-key"
}

data "aws_ssm_parameter" "ios_voip_push_certificate" {
  name = "${var.apns_ssm_parameter_prefix}/voip-certificate"
}

data "aws_ssm_parameter" "ios_voip_push_private_key" {
  name = "${var.apns_ssm_parameter_prefix}/voip-private-key"
}

locals {
  ios_push_platform_credential      = data.aws_ssm_parameter.ios_push_auth_key.value
  ios_voip_push_platform_credential = data.aws_ssm_parameter.ios_voip_push_private_key.value
  ios_voip_push_platform_principal  = data.aws_ssm_parameter.ios_voip_push_certificate.value
}
