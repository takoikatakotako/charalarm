# ローカル開発環境

MotoサーバーでAWSサービス(DynamoDB, SQS, SNS)をローカルにモックします。

## セットアップ

### 1. Motoサーバー起動

```bash
cd local
docker-compose up -d
```

### 2. テーブル作成

```bash
./createTable.sh
```

### 3. SQS/SNS作成

```bash
./createQueue.sh
```

## 使用するサービス

- **Moto**: `http://localhost:4566`
  - DynamoDB
  - SQS
  - SNS

## テーブル

- `user-table`: ユーザー情報
- `alarm-table`: アラーム設定
- `chara-table`: キャラクター情報

## SQS キュー

- `voip-push-queue.fifo`: VoIPプッシュ通知キュー
- `voip-push-dead-letter-queue.fifo`: デッドレターキュー

## SNS Platform Applications

- `ios-push-platform-application`: iOS プッシュ通知
- `ios-voip-push-platform-application`: iOS VoIP プッシュ通知

## クリーンアップ

```bash
docker-compose down
```
