#!/usr/bin/env bash
# user-table の既存ユーザーから registeredIPAddress を消す (#278)。
# IP アドレスは個人情報なのでサーバに残さない。
#
# 使い方:
#   ./remove-registered-ip.sh --profile charalarm-development-sso            # 件数を数えるだけ (dry-run)
#   ./remove-registered-ip.sh --profile charalarm-development-sso --apply    # 消す
set -euo pipefail

profile=""
apply=false
while [ $# -gt 0 ]; do
  case "$1" in
    --profile) profile="$2"; shift 2 ;;
    --apply) apply=true; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
if [ -z "$profile" ]; then
  echo "--profile を指定してください" >&2
  exit 1
fi

table="user-table"
region="ap-northeast-1"

# registeredIPAddress を持つユーザーの userID だけを取る (IP そのものは読まない)
user_ids=$(aws dynamodb scan \
  --profile "$profile" --region "$region" \
  --table-name "$table" \
  --filter-expression "attribute_exists(registeredIPAddress)" \
  --projection-expression "userID" \
  --query "Items[].userID.S" --output text | tr '\t' '\n' | sed '/^$/d')

count=$(printf '%s\n' "$user_ids" | sed '/^$/d' | wc -l | tr -d ' ')
echo "registeredIPAddress を持つユーザー: ${count} 件 (${profile})"

if [ "$apply" != true ]; then
  echo "dry-run なので消していません。消すときは --apply を付けてください"
  exit 0
fi

done_count=0
while read -r user_id; do
  [ -z "$user_id" ] && continue
  aws dynamodb update-item \
    --profile "$profile" --region "$region" \
    --table-name "$table" \
    --key "{\"userID\":{\"S\":\"${user_id}\"}}" \
    --update-expression "REMOVE registeredIPAddress" \
    --condition-expression "attribute_exists(userID)" >/dev/null
  done_count=$((done_count + 1))
  if [ $((done_count % 100)) -eq 0 ]; then
    echo "${done_count} / ${count}"
  fi
done <<< "$user_ids"

echo "消しました: ${done_count} 件"
