# GitHub Actions が AssumeRole するための信頼ポリシー
# 指定したリポジトリからの GitHub Actions のみに限定する
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # repo:<owner>/<repo>:* で該当リポジトリの全ブランチ・全イベントを許可
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:*"]
    }
  }
}

# GitHub Actions が AssumeRole する IAM ロール
resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# GitHub Actions に付与する IAM ポリシー
# ポリシーの内容は環境ごとに異なるため、変数で受け取る
resource "aws_iam_policy" "github_actions" {
  name   = var.policy_name
  policy = var.policy_json
}

# ロールにポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
