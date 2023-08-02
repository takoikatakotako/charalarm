# LocalStack

LocalStackのデバッグに良く使うコマンドです。

## LocalStackを作り直す

```
docker-compose down
docker-compose up -d
```


# S3

```
aws s3 ls --endpoint-url=http://localhost:4572
```



# DynamoDB

## テーブル一覧を表示

```
$ aws dynamodb list-tables --endpoint-url=http://localhost:4566
```

## テーブルの作成

```
$ aws dynamodb create-table \
    --table-name user-table3 \
    --attribute-definitions AttributeName=userID,AttributeType=S \
    --key-schema AttributeName=userID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --endpoint-url=http://localhost:4566 | jq
```

## テーブルの詳細を表示

```
$ aws dynamodb describe-table \
    --table-name user-table \
    --endpoint-url=http://localhost:4566 | jq
```


## Itemを取得

### アラームを取得

```
$ aws dynamodb get-item \
    --table-name alarm-table \
    --key '{"alarmID": {"S": "fd5fda81-194a-488e-80f1-52b02b0d6cc9"}}' \
    --endpoint-url=http://localhost:4566 | jq
```

### キャラ（com.charalarm.yui）を取得

```
$ aws dynamodb get-item \
    --table-name chara-table \
    --key '{"charaID": {"S": "com.charalarm.yui"}}' \
    --endpoint-url=http://localhost:4566 | jq
```

### キャラ（com.senpu-ki-soft.momiji）を取得

```
$ aws dynamodb get-item \
    --table-name chara-table \
    --key '{"charaID": {"S": "com.senpu-ki-soft.momiji"}}' \
    --endpoint-url=http://localhost:4566 | jq
```


## Itemを追加

### キャラ（com.charalarm.yui）を追加

```
$ aws dynamodb put-item \
    --table-name chara-table \
    --item '{"charaID":{"S":"com.charalarm.yui"},"charaEnable":{"BOOL":true},"charaName":{"S":"井上結衣"}}' \
    --endpoint-url=http://localhost:4566 | jq
```

### キャラ（com.senpu-ki-soft.momiji）を追加

```
$ aws dynamodb put-item \
    --table-name chara-table \
    --item '{"charaID":{"S":"com.senpu-ki-soft.momiji"},"charaEnable":{"BOOL":true},"charaName":{"S":"紅葉"}}' \
    --endpoint-url=http://localhost:4566 | jq
```


### クエリ

```
$ aws dynamodb query \
    --table-name alarm-table \
    --index-name user-id-index \
    --key-condition-expression "userID = :userID" \
    --expression-attribute-values '{ ":userID": { "S": "b87e945d-8912-4276-99f7-e636d7660093" } }' \
    --endpoint-url=http://localhost:4566
```

```
$ aws dynamodb query \
    --table-name alarm-table \
    --index-name alarm-time-index \
    --key-condition-expression "#time = :time" \
    --expression-attribute-names '{"#time":"time"}' \
    --expression-attribute-values '{ ":time": { "S": "XXXXX" } }' \
    --endpoint-url=http://localhost:4566
```


### スキャン

```
$ aws dynamodb scan \
    --table-name user-table \
    --endpoint-url=http://localhost:4566 | jq
```

```
$ aws dynamodb scan \
    --table-name alarm-table \
    --endpoint-url=http://localhost:4566 | jq
```

```
$ aws dynamodb scan \
    --table-name chara-table \
    --endpoint-url=http://localhost:4566 | jq
```

### テーブルの削除

```
$ aws dynamodb delete-table \
    --table-name user-table \ 
    --endpoint-url=http://localhost:4566
```


## SNS

### PlatformApplicationを作成

```
$ aws sns create-platform-application \
    --name ios-voip-push-platform-application \
    --platform APNS \
    --attributes PlatformCredential=DAMMY \
    --endpoint-url http://localhost:4566 | jq
```

### PlatformApplicationの一覧を表示

```
$ aws sns list-platform-applications \
    --endpoint-url http://localhost:4566 | jq
```

```
{
  "PlatformApplications": [
    {
      "PlatformApplicationArn": "arn:aws:sns:ap-northeast-1:000000000000:app/APNS/ios-voip-push-platform-application",
      "Attributes": {
        "PlatformCredential": "DAMMY"
      }
    }
  ]
}
```


### PlatformEndpointを作成

```
aws sns create-platform-endpoint \
  --platform-application-arn arn:aws:sns:ap-northeast-1:000000000000:app/APNS/ios-voip-push-platform-application \
  --token MY_TOKEN2 \
  --endpoint-url http://localhost:4566 | jq
```

### PlatformEndpointのEndpointsの一覧を確認

```
aws sns list-endpoints-by-platform-application \
  --platform-application-arn arn:aws:sns:ap-northeast-1:000000000000:app/APNS/ios-voip-push-platform-application \
  --endpoint-url http://localhost:4566

```

```
aws sns delete-platform-application \
  --platform-application-arn arn:aws:sns:ap-northeast-1:000000000000:app/APNS/my-topic3 \
  --endpoint-url http://localhost:4566
```


```
aws sns list-topics \
  --endpoint-url http://localhost:4566
```
  --platform-application-arn arn:aws:sns:ap-northeast-1:000000000000:app/APNS/ios-push-platform-application \
  --endpoint-url http://localhost:4566


# SQS

### キューの一覧を表示

```
$ aws sqs list-queues \
    --endpoint-url http://localhost:4566 | jq
```

### キューのメッセージ数を確認

```
$ aws sqs get-queue-attributes \
    --queue-url http://localhost:4566/000000000000/voip-push-queue.fifo \
    --attribute-names ApproximateNumberOfMessages \
    --endpoint-url http://localhost:4566 | jq
```

### キューのNotVisible状態のメッセージ数を確認

```
$ aws sqs get-queue-attributes \
    --queue-url http://localhost:4566/000000000000/voip-push-queue.fifo \
    --attribute-names ApproximateNumberOfMessagesNotVisible \
    --endpoint-url http://localhost:4566 | jq
```

### キューからメッセージを取得

```
$ aws sqs receive-message \
    --queue-url http://localhost:4566/000000000000/voip-push-queue.fifo \
    --max-number-of-messages 10 \
    --endpoint-url http://localhost:4566 | jq
```

### キュー内のメッセージをすべて削除

```
$ aws sqs purge-queue \
    --queue-url http://localhost:4566/000000000000/voip-push-queue.fifo \
    --endpoint-url http://localhost:4566 | jq
```
