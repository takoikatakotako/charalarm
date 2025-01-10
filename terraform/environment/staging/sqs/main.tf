# SQS
resource "aws_sqs_queue" "voip_push_queue" {
  name                        = "voip-push-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.voip_push_dead_letter_queue.arn
    maxReceiveCount     = 5
  })
  message_retention_seconds = 900 # メッセージを15分保持
}

resource "aws_sqs_queue" "voip_push_dead_letter_queue" {
  name                        = "voip-push-dead-letter-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 1209600 # メッセージを14日間保持（最大値）
}

resource "aws_lambda_event_source_mapping" "voip_push_queue_lambda_event_source_mapping" {
  event_source_arn = aws_sqs_queue.voip_push_queue.arn
  function_name    = var.worker_lambda_function_arn
}
