module "github_oidc" {
  source = "../../modules/github_oidc"

  tags = {
    Name    = "github-actions-oidc-provider"
    Project = "charalarm"
  }
}

# GitHub Actions に付与する権限を定義する
# ECR イメージ一覧の取得に必要な権限を付与する
data "aws_iam_policy_document" "github_actions_list_images" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:ListImages",
    ]
    resources = [
      "arn:aws:ecr:ap-northeast-1:448049807848:repository/charalarm-api",
      "arn:aws:ecr:ap-northeast-1:448049807848:repository/charalarm-admin-api",
      "arn:aws:ecr:ap-northeast-1:448049807848:repository/charalarm-batch",
      "arn:aws:ecr:ap-northeast-1:448049807848:repository/charalarm-worker",
    ]
  }
}

# GitHub Actions デプロイロール
# role_arn は GitHub Actions ワークフローの role-to-assume に設定する
module "github_actions_list_images_role" {
  source = "../../modules/github_actions_role"

  oidc_provider_arn = module.github_oidc.oidc_provider_arn
  github_repository = "takoikatakotako/charalarm"
  role_name         = "charalarm-management-github-actions-role"
  policy_name       = "charalarm-management-github-actions-policy"
  policy_json       = data.aws_iam_policy_document.github_actions_list_images.json
}

# terraform plan / apply を GitHub Actions から行うときに、state（このアカウントの S3）を読み書きするロール（#311）。
# 各環境のリソースを変えるロールは、それぞれの環境のアカウントにある（modules/terraform_ci_role）。
locals {
  terraform_state_bucket = "charalarm.terraform.state"
  terraform_ci_environments = {
    development = "terraform-development"
    staging     = "terraform-staging"
    production  = "terraform-production"
  }
}

data "aws_iam_policy_document" "terraform_state_plan" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.terraform_state_bucket}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [for environment in keys(local.terraform_ci_environments) : "arn:aws:s3:::${local.terraform_state_bucket}/${environment}/terraform.tfstate"]
  }
}

data "aws_iam_policy_document" "terraform_state_apply" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.terraform_state_bucket}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = [for environment in keys(local.terraform_ci_environments) : "arn:aws:s3:::${local.terraform_state_bucket}/${environment}/terraform.tfstate"]
  }
}

module "terraform_state_ci_role" {
  source = "../../modules/terraform_ci_role"

  oidc_provider_arn   = module.github_oidc.oidc_provider_arn
  github_repository   = "takoikatakotako/charalarm"
  github_environments = values(local.terraform_ci_environments)
  name_prefix         = "charalarm-state"
  plan_policy_json    = data.aws_iam_policy_document.terraform_state_plan.json
  apply_policy_json   = data.aws_iam_policy_document.terraform_state_apply.json
}
