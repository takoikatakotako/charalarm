# admin_api

管理画面 (`admin/`) 専用の REST API Lambda。CloudFront の Basic 認証の配下で動く。CloudFront が付ける秘密のヘッダ `X-Origin-Verify` を確かめ、それ以外のリクエストは弾く。

## エンドポイント

ルーティングの正は `main.go`。

- `GET /healthcheck`
- `GET /users?limit=20&cursor=<base64>` — ユーザー一覧 (DynamoDB Scan、`nextCursor` で次ページ)
- `GET /users/:userID` — ユーザー詳細
- `GET /users/:userID/alarms` — ユーザーのアラーム一覧
- `GET /news`・`POST /news`・`DELETE /news/:newsID` — お知らせ
- `GET /chara`・`POST /chara`・`GET /chara/:charaID`・`PUT /chara/:charaID` — キャラ
- `PUT /chara/:charaID/assets` — 表情・アラームのボイスなどのリソースの割り当て
- `GET /chara/:charaID/files`・`POST /chara/:charaID/files/upload-url`・`POST /chara/:charaID/files/invalidate` — リソースのファイル (S3 へのアップロード、CloudFront のキャッシュ削除)
- `GET /tap-line-themes`・`GET/PUT /chara/:charaID/tap-lines`・`POST /chara/:charaID/tap-lines/drafts`・`POST /chara/:charaID/tap-lines/voices` — タップのセリフ (Gemini で下書き・ボイス作り)

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
- CloudFront 配下に置く。Function URL は `NONE` 認証 (OAC だと POST のボディに署名できず 403 になるため)、かわりに秘密のヘッダで確かめる
- 権限: DynamoDB の読み取り、お知らせ・キャラ・タップのセリフの書き込み、リソースの S3 への書き込み、CloudFront のキャッシュ削除
