variable "oidc_provider_arn" {
  description = "GitHub Actions OIDC プロバイダーの ARN"
  type        = string
}

variable "github_repository" {
  description = "GitHub リポジトリ (owner/repo 形式)"
  type        = string
}

variable "github_environments" {
  description = "apply ロールを引き受けられる GitHub の Environment 名"
  type        = list(string)
}

variable "name_prefix" {
  description = "ロール名の先頭 (例: charalarm-dev)"
  type        = string
}

variable "plan_policy_arns" {
  description = "plan ロールに付ける管理ポリシーの ARN"
  type        = list(string)
  default     = []
}

variable "plan_policy_json" {
  description = "plan ロールに付けるインラインポリシー (不要なら null)"
  type        = string
  default     = null
}

variable "apply_policy_arns" {
  description = "apply ロールに付ける管理ポリシーの ARN"
  type        = list(string)
  default     = []
}

variable "apply_policy_json" {
  description = "apply ロールに付けるインラインポリシー (不要なら null)"
  type        = string
  default     = null
}
