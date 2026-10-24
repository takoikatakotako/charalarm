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
data "aws_iam_policy_document" "github_actions_deploy" {
  # Lambda デプロイ
  statement {
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
    ]
    resources = ["*"]
  }

  # ECR ログイン (management アカウントの ECR にアクセスするために必要)
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  # ECR イメージのプッシュ・取得
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:ListImages",
    ]
    resources = [
      "arn:aws:ecr:ap-northeast-1:448049807848:repository/charalarm-api",
      "arn:aws:ecr:ap-northeast-1:448049807848:repository/charalarm-admin-api",
      "arn:aws:ecr:ap-northeast-1:448049807848:repository/charalarm-batch",
      "arn:aws:ecr:ap-northeast-1:448049807848:repository/charalarm-worker",
    ]
  }

  # 管理画面フロントエンドの S3 同期 + CloudFront キャッシュ削除
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${local.prefix}-admin",
      "arn:aws:s3:::${local.prefix}-admin/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudfront:ListDistributions",
      "cloudfront:CreateInvalidation",
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
  role_name         = "${local.prefix}-github-actions-role"
  policy_name       = "${local.prefix}-github-actions-policy"
  policy_json       = data.aws_iam_policy_document.github_actions_deploy.json
}

# terraform plan / apply を GitHub Actions から行うロール（#311）
# plan は読み取りだけ。SecureString の SSM パラメータ（data で読む）を復号するため、SSM 経由の KMS 復号だけ足す。
# apply は Terraform が IAM も作るため、管理者権限を付ける。引き受けられるのは Environment の terraform-development だけ。
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
  github_environments = ["terraform-development"]
  name_prefix         = local.prefix
  plan_policy_arns    = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  plan_policy_json    = data.aws_iam_policy_document.terraform_plan.json
  apply_policy_arns   = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
