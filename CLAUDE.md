# Charalarm - プロジェクトガイド

キャラクターがモーニングコールしてくれるiOSアプリ「キャラアラーム」のモノレポ。

## プロジェクト構造

```
charalarm/
├── application/     # バックエンド (Go 1.27, Lambda)
│   ├── api/         # REST API (Echo)
│   ├── admin_api/   # 管理画面用 API (Echo, CloudFront 配下)
│   ├── batch/       # バッチ (EventBridge)。毎分のアラーム処理と、話題のニュース作り (trendnews)
│   └── worker/      # プッシュ通知送信 (SQS Consumer)
├── admin/           # 管理画面 (Next.js 16, 静的エクスポート)
├── ios/             # iOSアプリ (SwiftUI, iOS 18+, XcodeGen)
├── terraform/       # インフラ (AWS)
│   └── environment/ # development/staging/production/management
├── lp/              # ランディングページ
├── local/           # Moto開発環境 (DynamoDB/SQS/SNS)
├── storage/         # キャラクターリソース
└── docs/            # ドキュメント (MkDocs。mkdocs.yml で GitHub Pages に公開)
```

## 技術スタック

**iOS**: Swift, SwiftUI, Combine, Firebase, CallKit, PushKit, WKWebView + three-vrm (VRM 表示)
**Backend**: Go 1.27, Echo v4, AWS SDK v2
**外部サービス**: Gemini (Vertex AI。会話・音声合成・ニュース選び), WeatherKit REST (天気), X API News (話題のニュース), RevenueCat (課金)
**Infra**: Lambda, DynamoDB, SQS, SNS, S3, CloudFront, API Gateway, EventBridge
**IaC**: Terraform
**CI/CD**: GitHub Actions (OIDC認証)
**Test**: Moto (AWS モック)

## アーキテクチャ概要

```
iOS App → API Gateway → Lambda (API) → DynamoDB
                          │  /chat, /tts → Gemini (Vertex AI) / WeatherKit
                                          ↓
EventBridge (毎分) → Lambda (Batch) → SQS → Lambda (Worker) → SNS → iOS VoIP Push
EventBridge (1日数回) → Lambda (Batch, job=trendNews) → X API + Gemini → S3 (trend-news/ja.json, en.json)
```

- 会話 (`/chat`) は同期。会話の履歴・記憶・予定の中身は端末にだけ置き、サーバには保存しない
- アラームごとの電話の設定 (`call`: 長さ・予定・天気・ニュース) は alarm-table に置き、VoIP の中身 (値はすべて文字列) で届ける
- Secrets は SSM パラメータに置き、Lambda の環境変数に `ssm://` で書くと起動時に読む (application/environment)
- GCP (Vertex AI) へは Workload Identity Federation で入る。GCP 側の設定は別リポジトリ gcp-iac

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

# iOS (Mint でツール管理。プロジェクトは XcodeGen で作る)
cd ios && mint bootstrap
cd ios && mint run xcodegen generate

# ドキュメント
mkdocs serve
```

## 環境

| 環境 | Bundle ID | API | 管理画面 |
|------|-----------|-----|----------|
| Development | com.swiswiswift.sandbox.charalarm | api.charalarm-development.swiswiswift.com | admin.charalarm-development.swiswiswift.com |
| Staging | com.charalarm.staging | api.charalarm-staging.swiswiswift.com | - |
| Production | com.swiswiswift.CharacterAlarm | api3.charalarm.com | - |

## ブランチ戦略

- `main`: メインブランチ (PRのベース、リリース版)
- `feature/*`: 機能開発ブランチ
- `issue/*`: Issue対応ブランチ

## API認証

Basic認証: `userID:authToken` (クライアント生成UUID、Base64エンコード)

## DynamoDBテーブル

- `user-table`: ユーザー情報、プッシュトークン、プレミアム
- `alarm-table`: アラーム設定 (電話の設定 `call` を含む)
- `chara-table`: キャラクター情報 (見た目・会話・声の設定を含む)
- `chara-tap-line-table`: キャラをタップしたときのセリフ (管理画面で作る)
- `news-table`: アプリのお知らせ (管理画面で作る)
- `usage-table`: 会話・音声合成の回数 (上限チェック用、TTL で消える)

詳しくは docs/development/dynamodb.md

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
- Terraform は PR で各環境の plan が自動で走る。development は main へのマージで自動 apply、staging / production は手動の「Apply Terraform」ワークフローで apply する（production は承認あり）。management の composition は手元から apply する
- ローカル開発には Moto を使用 (LocalStack から移行済み)
