# GitHub Actions から terraform plan / apply するためのロール（#311）。
#
# - plan ロール: 読み取りだけ。PR と main から引き受けられる。
# - apply ロール: 変更できる。GitHub の Environment（terraform-<環境>）のジョブだけが引き受けられる。
#   Environment は main からしか動かせないように設定してあるので、PR のジョブは引き受けられない。
#
# フォークからの PR には OIDC トークンが発行されないため、どちらも引き受けられない。

data "aws_iam_policy_document" "plan_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repository}:pull_request",
        "repo:${var.github_repository}:ref:refs/heads/main",
      ]
    }
  }
}

data "aws_iam_policy_document" "apply_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for environment in var.github_environments : "repo:${var.github_repository}:environment:${environment}"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "${var.name_prefix}-terraform-plan-role"
  assume_role_policy = data.aws_iam_policy_document.plan_assume_role.json
}

resource "aws_iam_role_policy_attachments_exclusive" "plan" {
  role_name   = aws_iam_role.plan.name
  policy_arns = var.plan_policy_arns
}

resource "aws_iam_role_policy" "plan" {
  count = var.plan_policy_json == null ? 0 : 1

  name   = "${var.name_prefix}-terraform-plan-policy"
  role   = aws_iam_role.plan.id
  policy = var.plan_policy_json
}

resource "aws_iam_role" "apply" {
  name               = "${var.name_prefix}-terraform-apply-role"
  assume_role_policy = data.aws_iam_policy_document.apply_assume_role.json
}

resource "aws_iam_role_policy_attachments_exclusive" "apply" {
  role_name   = aws_iam_role.apply.name
  policy_arns = var.apply_policy_arns
}

resource "aws_iam_role_policy" "apply" {
  count = var.apply_policy_json == null ? 0 : 1

  name   = "${var.name_prefix}-terraform-apply-policy"
  role   = aws_iam_role.apply.id
  policy = var.apply_policy_json
}
