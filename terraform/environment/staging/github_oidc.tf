# GitHub Actions OIDC プロバイダー
# OIDC プロバイダーは AWS アカウントに1つしか作れないため、
# このモジュールはアカウントにつき1回だけ使用すること
module "github_oidc" {
  source = "../../modules/github_oidc"

  tags = {
    Name    = "github-actions-oidc-provider"
    Project = "charalarm"
  }
}

# GitHub Actions に付与する権限を定義する
# Lambda のイメージ更新に必要な権限のみを最小限で付与する
# stg/prod はイメージビルドを行わないため ECR 権限は不要
data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
    ]
    resources = ["*"]
  }
}

# GitHub Actions デプロイロール
# role_arn は GitHub Actions ワークフローの role-to-assume に設定する
module "github_actions_deploy_role" {
  source = "../../modules/github_actions_role"

  oidc_provider_arn = module.github_oidc.oidc_provider_arn
  github_repository = "takoikatakotako/charalarm"
  role_name         = "charalarm-stg-github-actions-role"
  policy_name       = "charalarm-stg-github-actions-policy"
  policy_json       = data.aws_iam_policy_document.github_actions_deploy.json
}
