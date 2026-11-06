# SQS

## voip-push-queue.fifo

バッチが毎分、時刻になったアラームを 1 件ずつ入れる。worker が受け取り、SNS で VoIP プッシュを送る。
構造体は `application/infrastructure/queue/aws_sqs.go` の `IOSVoIPPushAlarmInfoSQSMessage`。

```json
{
  "alarmID": "{UUID}",
  "userID": "{UUID}",
  "snsEndpointArn": "{SNS エンドポイントの ARN}",
  "charaID": "com.charalarm.yui",
  "charaName": "井上結衣",
  "voiceFileURL": "{URL}",
  "call": { "timeLimit": 60, "schedule": true, "weather": true, "news": false }
}
```

`call` はアラームに電話の設定があるときだけ入る。

FIFO キュー (内容で重複を除く)。メッセージは 15 分で消える。5 回受け取って失敗したものは `voip-push-dead-letter-queue.fifo` に移る。

## VoIP プッシュの中身

worker が SNS に送る中身 (`application/infrastructure/notification/aws_sns.go`)。
アプリは中身を `[String: String]` で読むので、値はすべて文字列にし、入れ子にしない (古いアプリが読めなくなるため)。

```json
{
  "charaID": "com.charalarm.yui",
  "charaName": "井上結衣",
  "voiceFileURL": "{URL}",
  "callTimeLimit": "60",
  "callSchedule": "true",
  "callWeather": "true",
  "callNews": "false"
}
```

`call*` はアラームに電話の設定があるときだけ入る。無ければアプリ共通の設定を使う。
