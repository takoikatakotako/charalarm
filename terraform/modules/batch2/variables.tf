variable "batch_function_image_uri" {
  type = string
}

variable "batch_function_image_tag" {
  type = string
}

variable "resource_base_url" {
  type = string
}

# 話題のニュース (trendNews)。X の Bearer Token は SecureString で Parameter Store に手で置き、そのパラメータ名を渡す。
# 空ならニュースは作らない
variable "x_bearer_token_ssm_parameter_name" {
  type    = string
  default = ""
}

# ニュースの JSON を置く resource のバケット
variable "resource_bucket_name" {
  type    = string
  default = ""
}

# ニュースを選ぶ Gemini (Vertex AI)。認証は API と同じ Workload Identity 連携
variable "gcp_project" {
  type    = string
  default = ""
}

variable "gcp_credential_config" {
  type    = string
  default = ""
}

variable "llm_model" {
  type    = string
  default = "gemini-3.1-flash-lite"
}

# 話題のニュースを作る時刻 (UTC)。既定は日本時間 4・10・16・22 時
variable "trend_news_schedule_expression" {
  type    = string
  default = "cron(0 1,7,13,19 * * ? *)"
}
