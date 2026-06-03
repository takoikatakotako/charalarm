##############################################################
# Monitoring (Slack 通知 + CloudWatch Alarm + Dashboard)
##############################################################
module "monitoring" {
  source                           = "../../modules/monitoring"
  name_prefix                      = local.prefix
  slack_webhook_ssm_parameter_name = "/charalarm/dev/slack-webhook-url"

  # コスト削減のため Dashboard は作成しない (Alarm / Slack 通知は維持)
  create_dashboard = false

  worker_function_name = module.worker.function_name
  batch_function_name  = module.batch.function_name

  api_function_names = [
    module.api.function_name,
    module.admin_api.function_name,
  ]

  voip_push_queue_name = "voip-push-queue.fifo"
  voip_push_dlq_name   = "voip-push-dead-letter-queue.fifo"

  api_cloudfront_distribution_ids = {
    api   = module.api.cloudfront_distribution_id
    admin = module.admin_frontend.cloudfront_distribution_id
  }
}
