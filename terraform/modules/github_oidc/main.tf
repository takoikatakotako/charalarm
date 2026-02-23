# GitHub Actions の OIDC トークン検証に使うサムプリントを取得する
# サムプリントは GitHub 側の証明書から自動取得するため、手動管理不要
data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# GitHub Actions と AWS を OIDC で連携するプロバイダー
# これにより、アクセスキーなしで GitHub Actions から AWS を操作できる
# OIDC プロバイダーは AWS アカウントに1つしか作れないため、
# このモジュールはアカウントにつき1回だけ使用すること
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
  tags            = var.tags
}
