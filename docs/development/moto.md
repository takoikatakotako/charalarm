# Moto

Moto (AWS サービスモック) のデバッグに良く使うコマンドです。

## Motoについて

- **目的**: DynamoDB, SQS, SNS などのAWSサービスをローカルでモック
- **ポート**: 4566
- **背景**: LocalStack Community Edition 終了(2026/3/23)に伴い移行

## Motoを作り直す

```bash
cd local
docker-compose down
docker-compose up -d
./createTable.sh
./createQueue.sh
```

# DynamoDB

## テーブル一覧を表示

```bash
aws dynamodb list-tables --endpoint-url=http://localhost:4566
```

## テーブルの作成

```bash
aws dynamodb create-table \
    --table-name user-table \
    --attribute-definitions AttributeName=userID,AttributeType=S \
    --key-schema AttributeName=userID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --endpoint-url=http://localhost:4566 \
    --region ap-northeast-1 | jq
```

## テーブルの詳細を表示

```bash
aws dynamodb describe-table \
    --table-name user-table \
    --endpoint-url=http://localhost:4566 | jq
```

## Itemを取得

### アラームを取得

```bash
aws dynamodb get-item \
    --table-name alarm-table \
    --key '{"alarmID": {"S": "fd5fda81-194a-488e-80f1-52b02b0d6cc9"}}' \
    --endpoint-url=http://localhost:4566 | jq
```

### キャラ（com.charalarm.yui）を取得

```bash
aws dynamodb get-item \
    --table-name chara-table \
    --key '{"charaID": {"S": "com.charalarm.yui"}}' \
    --endpoint-url=http://localhost:4566 | jq
```

### キャラ（com.senpu-ki-soft.momiji）を取得

```bash
aws dynamodb get-item \
    --table-name chara-table \
    --key '{"charaID": {"S": "com.senpu-ki-soft.momiji"}}' \
    --endpoint-url=http://localhost:4566 | jq
```

## Itemを追加

### キャラ（com.charalarm.yui）を追加

```bash
aws dynamodb put-item \
    --table-name chara-table \
    --item '{"charaID":{"S":"com.charalarm.yui"},"enable":{"BOOL":true},"name":{"S":"井上結衣"}}' \
    --endpoint-url=http://localhost:4566 | jq
```

### キャラ（com.senpu-ki-soft.momiji）を追加

```bash
aws dynamodb put-item \
    --table-name chara-table \
    --item '{"charaID":{"S":"com.senpu-ki-soft.momiji"},"enable":{"BOOL":true},"name":{"S":"紅葉"}}' \
    --endpoint-url=http://localhost:4566 | jq
```

## クエリ

```bash
aws dynamodb query \
    --table-name alarm-table \
    --index-name user-id-index \
    --key-condition-expression "userID = :userID" \
    --expression-attribute-values '{ ":userID": { "S": "b87e945d-8912-4276-99f7-e636d7660093" } }' \
    --endpoint-url=http://localhost:4566
```

```bash
aws dynamodb query \
    --table-name alarm-table \
    --index-name alarm-time-index \
    --key-condition-expression "#time = :time" \
    --expression-attribute-names '{"#time":"time"}' \
    --expression-attribute-values '{ ":time": { "S": "XXXXX" } }' \
    --endpoint-url=http://localhost:4566
```

## スキャン

```bash
aws dynamodb scan \
    --table-name user-table \
    --endpoint-url=http://localhost:4566 | jq
```

```bash
aws dynamodb scan \
    --table-name alarm-table \
    --endpoint-url=http://localhost:4566 | jq
```

```bash
aws dynamodb scan \
    --table-name chara-table \
    --endpoint-url=http://localhost:4566 | jq
```

## テーブルの削除

```bash
aws dynamodb delete-table \
    --table-name user-table \
    --endpoint-url=http://localhost:4566
```

# SNS

## PlatformApplicationを作成

```bash
aws sns create-platform-application \
    --name ios-voip-push-platform-application \
    --platform APNS \
    --attributes PlatformCredential=dummy-cert \
    --endpoint-url http://localhost:4566 | jq
```

## PlatformApplicationの一覧を表示

```bash
aws sns list-platform-applications \
    --endpoint-url http://localhost:4566 | jq
```

例:
```json
{
  "PlatformApplications": [
    {
      "PlatformApplicationArn": "arn:aws:sns:ap-northeast-1:123456789012:app/APNS/ios-voip-push-platform-application",
      "Attributes": {
        "PlatformCredential": "dummy-cert"
      }
    }
  ]
}
```

## PlatformEndpointを作成

```bash
aws sns create-platform-endpoint \
  --platform-application-arn arn:aws:sns:ap-northeast-1:123456789012:app/APNS/ios-voip-push-platform-application \
  --token MY_TOKEN \
  --endpoint-url http://localhost:4566 | jq
```

## PlatformEndpointの一覧を確認

```bash
aws sns list-endpoints-by-platform-application \
  --platform-application-arn arn:aws:sns:ap-northeast-1:123456789012:app/APNS/ios-voip-push-platform-application \
  --endpoint-url http://localhost:4566 | jq
```

# SQS

## キューの一覧を表示

```bash
aws sqs list-queues \
    --endpoint-url http://localhost:4566 | jq
```

## キューのURLを取得

```bash
aws sqs get-queue-url \
    --queue-name voip-push-queue.fifo \
    --endpoint-url http://localhost:4566 | jq
```

## キューのメッセージ数を確認

```bash
aws sqs get-queue-attributes \
    --queue-url http://localhost:4566/123456789012/voip-push-queue.fifo \
    --attribute-names ApproximateNumberOfMessages \
    --endpoint-url http://localhost:4566 | jq
```

## キューのNotVisible状態のメッセージ数を確認

```bash
aws sqs get-queue-attributes \
    --queue-url http://localhost:4566/123456789012/voip-push-queue.fifo \
    --attribute-names ApproximateNumberOfMessagesNotVisible \
    --endpoint-url http://localhost:4566 | jq
```

## キューからメッセージを取得

```bash
aws sqs receive-message \
    --queue-url http://localhost:4566/123456789012/voip-push-queue.fifo \
    --max-number-of-messages 10 \
    --endpoint-url http://localhost:4566 | jq
```

## キュー内のメッセージをすべて削除

```bash
aws sqs purge-queue \
    --queue-url http://localhost:4566/123456789012/voip-push-queue.fifo \
    --endpoint-url http://localhost:4566 | jq
```

# 注意事項

- **Queue URL形式**: Motoは `http://localhost:4566/123456789012/queue-name` 形式を使用 (LocalStackとは異なる)
- **Account ID**: Motoのデフォルトは `123456789012`
- **Region**: `ap-northeast-1` を明示的に指定すること
