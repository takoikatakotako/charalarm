##############################################################
# Monitoring (Slack 通知 + CloudWatch Alarm + Dashboard)
##############################################################
module "monitoring" {
  source                           = "../../modules/monitoring"
  name_prefix                      = local.prefix
  slack_webhook_ssm_parameter_name = "/charalarm/staging/slack-webhook-url"

  worker_function_name = module.worker2.function_name
  batch_function_name  = module.batch2.function_name

  api_function_names = [
    module.api.function_name,
  ]

  voip_push_queue_name = "voip-push-queue.fifo"
  voip_push_dlq_name   = "voip-push-dead-letter-queue.fifo"

  api_cloudfront_distribution_ids = {
    api = module.api.cloudfront_distribution_id
  }
}
