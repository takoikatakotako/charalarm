# Charalarm - プロジェクトガイド

キャラクターがモーニングコールしてくれるiOSアプリ「キャラアラーム」のモノレポ。

## プロジェクト構造

```
charalarm/
├── application/     # バックエンド (Go 1.24, Lambda)
│   ├── api/         # REST API (Echo)
│   ├── batch/       # 毎分実行バッチ (EventBridge)
│   └── worker/      # プッシュ通知送信 (SQS Consumer)
├── ios/             # iOSアプリ (SwiftUI, iOS 16+)
├── terraform/       # インフラ (AWS)
│   └── environment/ # development/staging/production/management
├── lp/              # ランディングページ
├── local/           # Moto開発環境 (DynamoDB/SQS/SNS)
├── storage/         # キャラクターリソース
└── documents/       # ドキュメント
```

## 技術スタック

**iOS**: Swift, SwiftUI, Combine, Firebase, Datadog, CallKit
**Backend**: Go 1.24, Echo v4, AWS SDK v2
**Infra**: Lambda, DynamoDB, SQS, SNS, S3, CloudFront, API Gateway, EventBridge
**IaC**: Terraform
**CI/CD**: GitHub Actions (OIDC認証)
**Test**: Moto (AWS モック)

## アーキテクチャ概要

```
iOS App → API Gateway → Lambda (API) → DynamoDB
                                          ↓
EventBridge (毎分) → Lambda (Batch) → SQS → Lambda (Worker) → SNS → iOS VoIP Push
```

## 主要コマンド

```bash
# Go テスト
cd application && make test

# イメージビルド&プッシュ
cd application && make build-api-image
cd application && make build-batch-image
cd application && make build-worker-image

# ローカル開発 (Moto)
cd local && docker-compose up -d
cd local && ./createTable.sh && ./createQueue.sh

# iOS (Mint でツール管理)
cd ios && mint bootstrap
```

## 環境

| 環境 | Bundle ID | API |
|------|-----------|-----|
| Development | com.swiswiswift.sandbox.charalarm | api.charalarm-development.com |
| Staging | com.charalarm.staging | api.charalarm-staging.com |
| Production | com.swiswiswift.CharacterAlarm | api3.charalarm.com |

## ブランチ戦略

- `main`: リリース版
- `develop`: 開発ブランチ (PRのベース)
- `feature/*`, `issue/*`: 機能開発
- `release/*`: リリース準備

## API認証

Basic認証: `userID:authToken` (クライアント生成UUID、Base64エンコード)

## DynamoDBテーブル

- `user-table`: ユーザー情報、プッシュトークン
- `alarm-table`: アラーム設定
- `chara-table`: キャラクター情報

## コード品質

- **iOS**: SwiftLint (--strict)
- **Go**: go fmt, go vulncheck
- PRで自動テスト実行

## キャラクターリソース

S3 + CloudFrontで配信。キャラIDはリバースドメイン形式 (例: `com.charalarm.yui`)

## テスト環境

**Moto** (AWSサービスモック):
- DynamoDB, SQS, SNS を統合的にモック
- ポート: 4566
- LocalStack Community Edition 終了(2026/3/23)に伴い移行

## 注意事項

- APNs証明書は1年で期限切れ (要定期更新)
- Lambda イメージは ECR にプッシュで自動デプロイ
- CloudFront キャッシュ削除は手動ワークフロー
- ローカル開発には Moto を使用 (LocalStack から移行済み)
