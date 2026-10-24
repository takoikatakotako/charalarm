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
# Lambda のイメージ更新と ECR イメージへの環境タグ付与に必要な権限を付与する
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

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:PutImage",
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

# terraform plan / apply を GitHub Actions から行うロール（#311）
# plan は読み取りだけ。SecureString の SSM パラメータ（data で読む）を復号するため、SSM 経由の KMS 復号だけ足す。
# apply は Terraform が IAM も作るため、管理者権限を付ける。引き受けられるのは Environment の terraform-staging だけ。
data "aws_iam_policy_document" "terraform_plan" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.ap-northeast-1.amazonaws.com"]
    }
  }
}

module "terraform_ci_role" {
  source = "../../modules/terraform_ci_role"

  oidc_provider_arn   = module.github_oidc.oidc_provider_arn
  github_repository   = "takoikatakotako/charalarm"
  github_environments = ["terraform-staging"]
  name_prefix         = local.prefix
  plan_policy_arns    = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  plan_policy_json    = data.aws_iam_policy_document.terraform_plan.json
  apply_policy_arns   = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
