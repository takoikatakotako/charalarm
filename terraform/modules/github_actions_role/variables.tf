# github_oidc モジュールの output から受け取る
variable "oidc_provider_arn" {
  description = "GitHub Actions OIDC プロバイダーの ARN"
  type        = string
}

# このリポジトリからの GitHub Actions のみ AssumeRole を許可する
variable "github_repository" {
  description = "GitHub リポジトリ (owner/repo 形式)"
  type        = string
}

variable "role_name" {
  description = "GitHub Actions が AssumeRole する IAM ロール名"
  type        = string
}

variable "policy_name" {
  description = "GitHub Actions に付与する IAM ポリシー名"
  type        = string
}

# 環境ごとに必要な権限が異なるため、呼び出し元で定義して渡す
variable "policy_json" {
  description = "GitHub Actions に付与する IAM ポリシーの JSON"
  type        = string
}
