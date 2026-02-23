
# GitHub Action Role
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
        "repo:takoikatakotako/charalarm:*",
        "repo:takoikatakotako/ZunTalk:*",
      ]
    }
  }
}

# GitHub Action Role Policy
resource "aws_iam_policy" "charalarm_github_action_role_policy" {
  name   = "charalarm-github-action-role-policy"
  policy = data.aws_iam_policy_document.charalarm_github_action_role_policy_document.json
}

data "aws_iam_policy_document" "charalarm_github_action_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:GetFunction",
    ]
    resources = [
      "arn:aws:lambda:ap-northeast-1:039612872248:function:charalarm-api",
      "arn:aws:lambda:ap-northeast-1:039612872248:function:batch-function2",
      "arn:aws:lambda:ap-northeast-1:039612872248:function:worker-function2",
      "arn:aws:lambda:ap-northeast-1:334832660826:function:charalarm-api",
      "arn:aws:lambda:ap-northeast-1:334832660826:function:batch-function2",
      "arn:aws:lambda:ap-northeast-1:334832660826:function:worker-function2",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "charalarm_github_action_role_policy_attachment" {
  role       = aws_iam_role.charalarm_github_action_role.name
  policy_arn = aws_iam_policy.charalarm_github_action_role_policy.arn
}


# Management Role
resource "aws_iam_role" "management_ci_role" {
  name               = "management-ci-role"
  assume_role_policy = data.aws_iam_policy_document.management_ci_role_assume_policy_document.json
}

data "aws_iam_policy_document" "management_ci_role_assume_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.charalarm_github_action_role.arn
      ]
    }
  }
}

resource "aws_iam_policy" "management_ci_role_policy" {
  name   = "management-ci-role-policy"
  policy = data.aws_iam_policy_document.management_ci_role_policy_document.json
}

data "aws_iam_policy_document" "management_ci_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "management_ci_role_policy_attachment" {
  role       = aws_iam_role.management_ci_role.name
  policy_arn = aws_iam_policy.management_ci_role_policy.arn
}
