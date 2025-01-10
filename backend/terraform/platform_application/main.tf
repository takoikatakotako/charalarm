###############################################
# Platfotm Application
###############################################
resource "aws_sns_platform_application" "ios_push_platform_application" {
  name                         = "ios-push-platform-application"
  platform                     = "APNS"
  success_feedback_sample_rate = 100
  platform_credential          = local.ios_push_platform_credential
  platform_principal           = var.ios_push_platform_principal
  apple_platform_team_id       = var.apple_platform_team_id
  apple_platform_bundle_id     = var.apple_platform_bundle_id

  lifecycle {
    ignore_changes = [
      # なぜかTerraformから設定できないためignoreに設定している
      platform_credential
    ]
  }
}

resource "aws_sns_platform_application" "ios_voip_push_platform_application" {
  name                         = "ios-voip-push-platform-application"
  platform                     = "APNS_VOIP"
  success_feedback_sample_rate = 100
  platform_credential          = local.ios_voip_push_platform_credential
  platform_principal           = local.ios_voip_push_platform_principal
}
