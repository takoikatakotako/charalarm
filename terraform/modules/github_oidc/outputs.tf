# github_actions_role モジュールに渡す ARN を出力する
output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}
