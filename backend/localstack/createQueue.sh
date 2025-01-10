#!/bin/bash
set -x

awslocal sqs create-queue \
  --queue-name voip-push-queue.fifo \
  --attributes FifoQueue=true,ContentBasedDeduplication=true

awslocal sqs create-queue \
  --queue-name voip-push-dead-letter-queue.fifo \
  --attributes FifoQueue=true,ContentBasedDeduplication=true

set +x
