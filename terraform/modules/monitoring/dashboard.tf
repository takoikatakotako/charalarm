locals {
  lambda_function_names = concat(
    var.api_function_names,
    [var.worker_function_name, var.batch_function_name],
  )

  # Lambda 共通メトリクス 3 列 (Invocations / Errors / Duration)
  lambda_widget_rows = [
    for idx, fn in local.lambda_function_names : [
      {
        type   = "metric"
        x      = 0
        y      = idx * 6
        width  = 8
        height = 6
        properties = {
          title   = "${fn} — Invocations"
          region  = local.region
          view    = "timeSeries"
          stacked = false
          period  = 60
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", fn, { stat = "Sum" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = idx * 6
        width  = 8
        height = 6
        properties = {
          title   = "${fn} — Errors / Throttles"
          region  = local.region
          view    = "timeSeries"
          stacked = false
          period  = 60
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", fn, { stat = "Sum" }],
            [".", "Throttles", ".", ".", { stat = "Sum" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = idx * 6
        width  = 8
        height = 6
        properties = {
          title  = "${fn} — Duration (ms)"
          region = local.region
          view   = "timeSeries"
          period = 60
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", fn, { stat = "Average", label = "avg" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "Maximum", label = "max" }],
          ]
        }
      },
    ]
  ]

  # SQS 行 (Lambda 全行の下)
  sqs_y = length(local.lambda_function_names) * 6

  sqs_widgets = [
    {
      type   = "metric"
      x      = 0
      y      = local.sqs_y
      width  = 12
      height = 6
      properties = {
        title  = "SQS — Messages Visible"
        region = local.region
        view   = "timeSeries"
        period = 60
        metrics = [
          ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.voip_push_queue_name, { label = "main" }],
          ["...", var.voip_push_dlq_name, { label = "DLQ" }],
        ]
      }
    },
    {
      type   = "metric"
      x      = 12
      y      = local.sqs_y
      width  = 12
      height = 6
      properties = {
        title  = "SQS — Age of Oldest Message (sec)"
        region = local.region
        view   = "timeSeries"
        period = 60
        metrics = [
          ["AWS/SQS", "ApproximateAgeOfOldestMessage", "QueueName", var.voip_push_queue_name, { label = "main" }],
          ["...", var.voip_push_dlq_name, { label = "DLQ" }],
        ]
      }
    },
  ]

  # CloudFront 行 (SQS の下)。CloudFront メトリクスは us-east-1 リージョンで取得する必要あり
  cloudfront_y = local.sqs_y + 6

  cloudfront_widgets = [
    for idx, entry in chunklist([for k, v in var.api_cloudfront_distribution_ids : { label = k, id = v }], 1) :
    {
      type   = "metric"
      x      = (idx % 3) * 8
      y      = local.cloudfront_y + floor(idx / 3) * 6
      width  = 8
      height = 6
      properties = {
        title  = "CloudFront ${entry[0].label} — Requests / Errors"
        region = "us-east-1"
        view   = "timeSeries"
        period = 300
        metrics = [
          ["AWS/CloudFront", "Requests", "DistributionId", entry[0].id, "Region", "Global", { stat = "Sum", label = "requests" }],
          [".", "4xxErrorRate", ".", ".", ".", ".", { stat = "Average", label = "4xx %" }],
          [".", "5xxErrorRate", ".", ".", ".", ".", { stat = "Average", label = "5xx %" }],
        ]
      }
    }
  ]

  dashboard_body = jsonencode({
    widgets = concat(
      flatten(local.lambda_widget_rows),
      local.sqs_widgets,
      local.cloudfront_widgets,
    )
  })
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.name_prefix
  dashboard_body = local.dashboard_body
}
