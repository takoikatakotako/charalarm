# admin_api

管理画面 (`admin/`) 専用の REST API Lambda。CloudFront OAC + Basic 認証配下で動作する前提のため、アプリレベルの認証は持たない。

## エンドポイント

- `GET /healthcheck`
- `GET /users?limit=20&cursor=<base64>` — ユーザー一覧 (DynamoDB Scan、`nextCursor` で次ページ)
- `GET /users/:userID` — ユーザー詳細
- `GET /users/:userID/alarms` — ユーザーのアラーム一覧

## ローカル実行

Moto (ポート 4566) を立ち上げた状態で:

```bash
cd application
PORT=8081 go run admin_api/main.go
```

## デプロイ

- イメージビルド & push: `make build-admin-api-image` (ECR: `charalarm-admin-api`)
- Lambda 関数: `charalarm-dev-admin-api`
- GitHub Actions (`deploy-dev.yml`) で `main` への `application/**` 変更時に自動ビルド & デプロイ

## インフラ

- Terraform モジュール: `terraform/modules/admin_api/`
- CloudFront 配下に配置され、Function URL は `AWS_IAM` 認証 (OAC 経由のみアクセス可)
- 権限: DynamoDB 読み取りのみ (GetItem, Scan, Query)
