#!/usr/bin/env bash
# APNs の鍵と証明書を、環境の SSM（SecureString）に置く（#311）。
# Terraform（modules/platform_application）はここから読むので、CI からも plan / apply できる。
# VoIP の証明書を更新したら、新しいファイルでこれを実行してから apply する。値は表示しない。
#
# 使い方: put-apns-credentials.sh <development|staging|production> <AuthKey.p8> <voip-certificate.pem> <voip-privatekey.pem>
# 例:     put-apns-credentials.sh development \
#           environment/development/.credentials/AuthKey_NL6K5FR5S8.p8 \
#           environment/development/.credentials/development-voip-expiration-20270507-certificate.pem \
#           environment/development/.credentials/development-voip-expiration-20270507-privatekey.pem
set -euo pipefail

if [ $# -ne 4 ]; then
  sed -n '6,7p' "$0" >&2
  exit 1
fi

environment="$1"
case "$environment" in
  development) prefix=/charalarm/dev/apns ;;
  staging) prefix=/charalarm/staging/apns ;;
  production) prefix=/charalarm/production/apns ;;
  *) echo "unknown environment: $environment" >&2; exit 1 ;;
esac

put() {
  aws ssm put-parameter --profile "charalarm-${environment}-sso" --region ap-northeast-1 \
    --name "$prefix/$1" --type SecureString --overwrite --value "file://$2" \
    --query Version --output text | sed "s|^|$prefix/$1 version |"
}

put push-auth-key "$2"
put voip-certificate "$3"
put voip-private-key "$4"
