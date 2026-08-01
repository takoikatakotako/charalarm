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
