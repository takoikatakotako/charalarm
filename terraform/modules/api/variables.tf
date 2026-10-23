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

variable "api_lambda_function_image_tag" {
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

variable "resource_base_url" {
  type = string
}

# ずんだもん会話用 LLM (デフォルト OpenAI) の API キーを保持する SSM パラメータ名。
# 秘密値は SSM Parameter Store (SecureString) に手動投入し、名前だけを渡す。
variable "openai_api_key_ssm_parameter_name" {
  type = string
}

# RevenueCat の Webhook に設定する Authorization ヘッダの値を保持する SSM パラメータ名。
# 秘密値は SSM Parameter Store (SecureString) に手動投入し、名前だけを渡す。空なら Webhook は受けない。
variable "revenuecat_webhook_authorization_ssm_parameter_name" {
  type    = string
  default = ""
}

variable "llm_provider" {
  type    = string
  default = "openai"
}

variable "llm_model" {
  type    = string
  default = "gpt-4o-mini"
}

# 音声合成 (Vertex AI の Gemini TTS)。gcp_project が空なら /tts は 503 を返す。
variable "gcp_project" {
  type    = string
  default = ""
}

# Workload Identity 連携の credential config (external_account の JSON)。秘密値は含まない。
variable "gcp_credential_config" {
  type    = string
  default = ""
}

variable "tts_model" {
  type    = string
  default = "gemini-3.8-flash-tts"
}

variable "tts_voice" {
  type    = string
  default = "ja-jp-advisor-5"
}
