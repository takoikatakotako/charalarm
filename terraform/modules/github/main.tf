# 
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

# see: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html
# see: https://github.com/aws-actions/configure-aws-credentials/issues/357#issuecomment-1011642085
data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# IAM Role
resource "aws_iam_role" "charalarm_github_action_role" {
  name               = "charalarm-github-action-role"
  assume_role_policy = data.aws_iam_policy_document.charalarm_github_action_role_assume_policy_document.json
}

data "aws_iam_policy_document" "charalarm_github_action_role_assume_policy_document" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:takoikatakotako/charalarm-backend:*",
        "repo:takoikatakotako/charalarm-ios:*",
        "repo:takoikatakotako/charalarm-docs:*",
        "repo:takoikatakotako/charalarm-lp:*"
      ]
    }
  }
}

# Policy
resource "aws_iam_policy" "charalarm_github_action_role_policy" {
  name   = "charalarm-github-action-role-policy"
  policy = data.aws_iam_policy_document.charalarm_github_action_role_policy_document.json
}

data "aws_iam_policy_document" "charalarm_github_action_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListObjectsV2",
      "s3:DeleteObject",
      "lambda:UpdateFunctionCode",
      "cloudfront:CreateInvalidation"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "charalarm_github_action_role_policy_attachment" {
  role       = aws_iam_role.charalarm_github_action_role.name
  policy_arn = aws_iam_policy.charalarm_github_action_role_policy.arn
}
