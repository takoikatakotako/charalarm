# Lambda が自動で作っていた api のロググループを取り込み、保持期間を付ける (#278)
import {
  to = module.api.aws_cloudwatch_log_group.api_log_group
  id = "/aws/lambda/charalarm-api"
}

# 管理 API のロググループも同じく取り込む
import {
  to = module.admin_api.aws_cloudwatch_log_group.admin_api_log_group
  id = "/aws/lambda/${local.prefix}-admin-api"
}
