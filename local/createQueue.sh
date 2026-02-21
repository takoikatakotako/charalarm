#!/bin/bash
set -x

ENDPOINT_URL=${AWS_ENDPOINT:-http://localhost:4566}

# Create SQS FIFO Queues
# Dead Letter Queue
aws sqs create-queue \
    --endpoint-url $ENDPOINT_URL \
    --queue-name voip-push-dead-letter-queue.fifo \
    --attributes '{"FifoQueue":"true","ContentBasedDeduplication":"true"}' \
    --region ap-northeast-1

# Main Queue
aws sqs create-queue \
    --endpoint-url $ENDPOINT_URL \
    --queue-name voip-push-queue.fifo \
    --attributes '{"FifoQueue":"true","ContentBasedDeduplication":"true"}' \
    --region ap-northeast-1

# Create SNS Platform Applications
# iOS Push Platform Application
aws sns create-platform-application \
    --endpoint-url $ENDPOINT_URL \
    --name ios-push-platform-application \
    --platform APNS \
    --attributes PlatformCredential=dummy-cert \
    --region ap-northeast-1

# iOS VoIP Push Platform Application
aws sns create-platform-application \
    --endpoint-url $ENDPOINT_URL \
    --name ios-voip-push-platform-application \
    --platform APNS \
    --attributes PlatformCredential=dummy-cert \
    --region ap-northeast-1

set +x
