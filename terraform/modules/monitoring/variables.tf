variable "name_prefix" {
  type        = string
  description = "リソース名のプレフィックス (例: charalarm-dev)"
}

variable "slack_webhook_ssm_parameter_name" {
  type        = string
  description = "Slack Webhook URL を格納した SSM Parameter 名 (SecureString)"
}

variable "api_function_names" {
  type        = list(string)
  description = "Dashboard に表示する API Lambda の関数名リスト"
  default     = []
}

variable "worker_function_name" {
  type        = string
  description = "VoIP Push Worker Lambda の関数名 (Errors アラーム対象)"
}

variable "batch_function_name" {
  type        = string
  description = "Batch Lambda の関数名 (Invocations ハートビート対象)"
}

variable "voip_push_queue_name" {
  type        = string
  description = "VoIP Push メインキュー名"
}

variable "voip_push_dlq_name" {
  type        = string
  description = "VoIP Push DLQ 名 (深さ > 0 アラーム対象)"
}

variable "api_cloudfront_distribution_ids" {
  type        = map(string)
  description = "Dashboard に表示する CloudFront distribution ID のマップ (ラベル → ID)"
  default     = {}
}
