# GitHub Actions ワークフローの role-to-assume に設定する ARN
output "role_arn" {
  value = aws_iam_role.github_actions.arn
}
