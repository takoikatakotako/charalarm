# Lambda が自動で作っていた api のロググループを取り込み、保持期間を付ける (#278)
import {
  to = module.api.aws_cloudwatch_log_group.api_log_group
  id = "/aws/lambda/charalarm-api"
}
