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
