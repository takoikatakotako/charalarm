# Charalarm Admin

キャラアラームの管理画面 (Next.js + TypeScript + Tailwind CSS v4 + shadcn/ui)。

本番ビルドは静的エクスポート (`output: 'export'`) で S3 + CloudFront に配信する。

## 開発

```bash
# admin_api を別ターミナルで起動 (ポート 8081)
cd application
PORT=8081 go run admin_api/main.go  # Moto を起動した状態で

# admin をローカルで起動 (ポート 3000)
cd admin
npm install
npm run dev
```

`next.config.ts` の `rewrites` で開発時は `/api/*` を `NEXT_PUBLIC_ADMIN_API_URL` (デフォルト `http://localhost:8081`) に転送する。本番ビルド (`output: 'export'`) では rewrites は無効化され、CloudFront の `/api/*` behavior が Lambda にルーティングする。

## Basic 認証の SSM Parameter (初回のみ手動作成)

Basic 認証のユーザー名/パスワードは SSM Parameter Store に平文で保存する (tfstate には載せない)。

```bash
# development 環境 (charalarm-development-sso プロファイル)
aws ssm put-parameter \
  --name /charalarm/dev/admin/basic-auth-user \
  --type String \
  --value 'admin' \
  --profile charalarm-development-sso \
  --region ap-northeast-1

aws ssm put-parameter \
  --name /charalarm/dev/admin/basic-auth-password \
  --type SecureString \
  --value 'ここにランダムな長いパスワード' \
  --profile charalarm-development-sso \
  --region ap-northeast-1
```

パスワード変更時も `put-parameter --overwrite` で更新し、terraform apply すると CloudFront Function のコードに埋め込まれる認証情報が更新される。

## デプロイ

`main` ブランチに `admin/**` への変更が push されると `deploy-dev.yml` がフロントエンドをビルドして S3 に sync + CloudFront invalidation する。手動で実行するには GitHub Actions の `Deploy(Dev)` ワークフローを workflow_dispatch で起動。

## エンドポイント URL

- 開発: https://admin.charalarm-development.swiswiswift.com/

## 使っているライブラリ

- Next.js 16 (App Router, `output: 'export'`)
- React 19
- Tailwind CSS v4
- shadcn/ui (style: base-nova)
- SWR (データフェッチ)
- lucide-react (アイコン)
- sonner (toast)
