#!/usr/bin/env bash
# terraform の provider / backend が使う AWS のプロファイルを、GitHub Actions の OIDC で作る（#311）。
#
# 手元では SSO のプロファイル（charalarm-management-sso など）を使っている。CI でも同じ名前の
# プロファイルを、OIDC トークンでロールを引き受ける形で用意する。こうすると terraform のコードは変えずに済む。
#
# 使い方: terraform-aws-profiles.sh <development|staging|production> <plan|apply>
set -euo pipefail

environment="$1"
mode="$2"

case "$environment" in
  development) account_id=039612872248 prefix=charalarm-dev ;;
  staging) account_id=334832660826 prefix=charalarm-staging ;;
  production) account_id=986921280333 prefix=charalarm-production ;;
  *) echo "unknown environment: $environment" >&2; exit 1 ;;
esac

case "$mode" in
  plan | apply) ;;
  *) echo "unknown mode: $mode" >&2; exit 1 ;;
esac

management_account_id=448049807848
token_file="$RUNNER_TEMP/aws-web-identity-token"

# OIDC トークンを取る。SDK は期限が切れそうになるとこのファイルを読み直すので、短い実行なら取り直しは不要。
curl -fsS -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" | jq -r .value > "$token_file"
chmod 600 "$token_file"

mkdir -p ~/.aws
cat > ~/.aws/config <<CONFIG
[profile charalarm-management-sso]
role_arn = arn:aws:iam::${management_account_id}:role/charalarm-state-terraform-${mode}-role
web_identity_token_file = ${token_file}
role_session_name = github-actions-terraform-${mode}
region = ap-northeast-1

[profile charalarm-${environment}-sso]
role_arn = arn:aws:iam::${account_id}:role/${prefix}-terraform-${mode}-role
web_identity_token_file = ${token_file}
role_session_name = github-actions-terraform-${mode}
region = ap-northeast-1
CONFIG
