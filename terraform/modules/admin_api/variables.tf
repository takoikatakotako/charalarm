variable "function_name" {
  type = string
}

variable "image_uri" {
  type = string
}

variable "image_tag" {
  type = string
}

# CloudFront が注入する共有秘密ヘッダの値を保持する SSM パラメータ名
# (admin の Basic 認証パスワードを流用)。
variable "origin_secret_ssm_parameter_name" {
  type = string
}

# キャラのリソース (S3 + CloudFront)。管理画面からアップロードする
variable "resource_bucket_name" {
  type = string
}

variable "resource_bucket_arn" {
  type = string
}

variable "resource_distribution_id" {
  type = string
}

variable "resource_distribution_arn" {
  type = string
}

# タップのセリフの下書き (Gemini の LLM) とボイス (Gemini TTS) に使う Vertex AI。空なら作れない
variable "gcp_project" {
  type    = string
  default = ""
}

# Workload Identity 連携の credential config (external_account の JSON)。秘密値は含まない
variable "gcp_credential_config" {
  type    = string
  default = ""
}

variable "llm_model" {
  type    = string
  default = ""
}
