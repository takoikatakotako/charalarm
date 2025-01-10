variable "apple_platform_team_id" {
  type = string
}

variable "apple_platform_bundle_id" {
  type = string
}

variable "ios_push_credential_file" {
  type = string
}

variable "ios_push_platform_principal" {
  type = string
}

variable "ios_voip_push_certificate_file" {
  type = string
}

variable "ios_voip_push_private_file" {
  type = string
}

locals {
  ios_push_platform_credential      = file(".credentials/${var.ios_push_credential_file}")
  ios_voip_push_platform_credential = file(".credentials/${var.ios_voip_push_private_file}")
  ios_voip_push_platform_principal  = file(".credentials/${var.ios_voip_push_certificate_file}")
}
