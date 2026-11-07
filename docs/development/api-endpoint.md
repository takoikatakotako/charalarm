# API エンドポイント

アプリが使う API (`application/api`) の一覧です。ルーティングの正は `application/api/main.go`、
リクエスト・レスポンスの形は `application/api/handler/request`・`handler/response` にあります。

## 環境

| 環境 | API | リソース (S3 + CloudFront) |
|---|---|---|
| Development | https://api.charalarm-development.swiswiswift.com | https://resource.charalarm-development.swiswiswift.com |
| Staging | https://api.charalarm-staging.swiswiswift.com | https://resource.charalarm-staging.swiswiswift.com |
| Production | https://api3.charalarm.com | https://resource.charalarm.com |

## 認証

`🔒` のついたエンドポイントは Basic 認証です。`userID:authToken` (アプリが作った UUID) を Base64 にして送ります。

```sh
API=https://api.charalarm-development.swiswiswift.com
USER_ID=20f0c1cd-9c2a-411a-878c-9bd0bb15dc35
AUTH_TOKEN=038a5e28-15ce-46b4-8f46-4934202faa85
AUTH="Authorization: Basic $(echo -n $USER_ID:$AUTH_TOKEN | base64)"
```

### App Check

アプリは Firebase App Check (中身は App Attest) のトークンを `X-Firebase-AppCheck` ヘッダに付けます。
サーバは Firebase の公開鍵で確かめ、結果をログ (`app check` の `result`) に出します。

- `CHARALARM_APP_CHECK_MODE` が `monitor` なら記録するだけ、`enforce` なら `/chat`・`/tts`・`/weather` で正しいトークンの無いリクエストを 401 で弾く
- `/user/signup` は 4.x のアプリ (トークンを送らない) も呼ぶので、`enforce` でも記録するだけ
- Simulator は App Attest を使えないので、デバッグ用のトークン (Xcode のコンソールに出る) を Firebase のコンソールに登録して使う

成功・失敗だけを返すエンドポイントは `{"message": "..."}` を返します。認証に失敗すると 401 です。

## 一覧

| メソッド | パス | 認証 | 内容 |
|---|---|---|---|
| GET | /healthcheck | | ヘルスチェック |
| GET | /maintenance | | メンテナンス中か |
| GET | /require | | アプリの必要な最低バージョン |
| POST | /user/signup | | ユーザー登録 |
| POST | /user/withdraw | 🔒 | 退会 |
| GET | /user/info | 🔒 | ユーザーの情報 |
| GET | /alarm/list | 🔒 | アラームの一覧 |
| POST | /alarm/add | 🔒 | アラームを足す |
| POST | /alarm/edit | 🔒 | アラームを変える |
| POST | /alarm/delete | 🔒 | アラームを消す |
| GET | /chara/list | | キャラの一覧 |
| GET | /chara/id/:charaID | | キャラ 1 人 |
| POST | /push-token/ios/push/add | 🔒 | 通常のプッシュのトークンを登録 |
| POST | /push-token/ios/voip-push/add | 🔒 | VoIP プッシュのトークンを登録 |
| GET | /news/list | | お知らせの一覧 |
| POST | /chat | 🔒 | キャラとの会話 |
| POST | /tts | 🔒 | キャラの声で読み上げ |
| POST | /weather | 🔒 | 地域の今日の天気 (トップに出す) |
| POST | /webhook/revenuecat | (秘密のヘッダ) | RevenueCat からの課金の通知 |

---

## GET: /healthcheck

```sh
curl $API/healthcheck
```

```json
{ "message": "Healthy!" }
```

## GET: /maintenance

```json
{ "maintenance": false }
```

## GET: /require

```json
{ "iosVersion": "5.0.0" }
```

アプリはこれより古ければアップデートを促します。

---

## POST: /user/signup

`userID`・`authToken` はアプリが作った UUID で、アプリの Keychain に持ちます。登録済みでも成功を返します。

```sh
curl -X POST $API/user/signup -H 'Content-Type: application/json' \
  -d "{\"userID\":\"$USER_ID\",\"authToken\":\"$AUTH_TOKEN\",\"platform\":\"iOS\"}"
```

## POST: /user/withdraw 🔒

プッシュの SNS エンドポイント、そのエンドポイント宛てのアラーム、ユーザーを消します。

```sh
curl -X POST $API/user/withdraw -H "$AUTH"
```

## GET: /user/info 🔒

```sh
curl $API/user/info -H "$AUTH"
```

```json
{
  "userID": "20f0c1cd-9c2a-411a-878c-9bd0bb15dc35",
  "authToken": "03**********************************",
  "platform": "iOS",
  "premiumPlan": false,
  "iOSPlatformInfo": {
    "pushToken": "",
    "pushTokenSNSEndpoint": "",
    "voIPPushToken": "",
    "voIPPushTokenSNSEndpoint": ""
  }
}
```

---

## アラーム

アラームの形です。`hour`・`minute`・曜日は端末の時刻 (現地) で送り、`timeDifference` に UTC からの時差 (時間) を入れます。
サーバは UTC に直して保存し、返すときに現地に戻します ([DynamoDB](dynamodb.md#alarm-table))。

```json
{
  "alarmID": "45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7",
  "userID": "20f0c1cd-9c2a-411a-878c-9bd0bb15dc35",
  "type": "IOS_VOIP_PUSH_NOTIFICATION",
  "enable": true,
  "name": "平日",
  "hour": 7,
  "minute": 30,
  "timeDifference": 9,
  "charaID": "com.charalarm.yui",
  "charaName": "井上結衣",
  "voiceFileName": "",
  "sunday": false,
  "monday": true,
  "tuesday": true,
  "wednesday": true,
  "thursday": true,
  "friday": true,
  "saturday": false,
  "call": { "timeLimit": 60, "schedule": true, "weather": true, "news": false }
}
```

- `type`: `IOS_VOIP_PUSH_NOTIFICATION` (電話) か `IOS_PUSH_NOTIFICATION` (通知)
- `call`: 電話 (AI 会話) の設定。省略するとアプリ共通の設定を使う。`timeLimit` は 30 / 60 / 90 / 120 / 180 秒のどれかで、それ以外は 400

### GET: /alarm/list 🔒

アラームの配列を返します。

### POST: /alarm/add 🔒 ・ POST: /alarm/edit 🔒

```sh
curl -X POST $API/alarm/add -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"alarm": { ...上のアラーム... }}'
```

### POST: /alarm/delete 🔒

```sh
curl -X POST $API/alarm/delete -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"alarmID":"45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7"}'
```

---

## GET: /chara/list ・ GET: /chara/id/:charaID

`enable` のキャラを返します (一覧は配列、`/chara/id` は 1 人)。ファイルはリソースの URL で返します。

```json
{
  "charaID": "com.charalarm.yui",
  "enable": true,
  "name": "井上結衣",
  "createdAt": "2023-06-03",
  "updatedAt": "2023-06-14",
  "description": "...",
  "profiles": [{ "title": "声優", "name": "...", "url": "https://..." }],
  "resources": [{ "fileURL": "https://resource.../com.charalarm.yui/thumbnail.png" }],
  "expressions": {
    "normal": { "imageFileURLs": ["https://..."], "voiceFileURLs": ["https://..."] }
  },
  "calls": [{ "message": "...", "voiceFileName": "...", "voiceFileURL": "https://..." }],
  "appearance": { "type": "vrm", "modelFileURL": "https://.../yui.vrm" },
  "appearances": [{ "type": "illustration" }, { "type": "vrm", "modelFileURL": "https://..." }],
  "tapLines": [
    { "language": "ja", "text": "...", "voiceFileURL": "https://...", "when": { "dates": [], "hours": [5, 11], "weekdays": [] } }
  ],
  "conversation": {
    "voiceProvider": "gemini",
    "voicevoxStyleID": 0,
    "languages": ["ja", "en"],
    "openingPrompt": "...",
    "endingPrompt": "...",
    "noInputEndingPrompt": "..."
  }
}
```

- `conversation` は会話できるキャラだけ。`voiceProvider` が `voicevox` なら端末で、`gemini` なら `/tts` で声を作る
- `tapLines` はトップでキャラをタップしたときのセリフ。`when` の空の項目は条件にしない

---

## POST: /push-token/ios/push/add 🔒 ・ POST: /push-token/ios/voip-push/add 🔒

トークンを SNS のエンドポイントにして user-table に保存します。

```json
{ "pushToken": "78e1c441fece443abaa519b697b297e1" }
```

## GET: /news/list

アプリの「お知らせ」 (news-table)。話題のニュース (X) はここではなく、リソースの `trend-news/ja.json`・`trend-news/en.json` です。

```json
[{ "newsId": "...", "title": "...", "body": "...", "registeredAt": "2026-11-01T00:00:00Z" }]
```

---

## POST: /chat 🔒

キャラとの会話。人格プロンプトはサーバで付けます。履歴・記憶は端末が持ち、毎回送ります (サーバには保存しない)。

```json
{
  "charaID": "com.charalarm.yui",
  "language": "ja",
  "capabilities": ["calendar.read"],
  "todayEvents": "[{\"title\":\"...\",\"start\":\"09:00\",\"end\":\"10:00\",\"allDay\":false}]",
  "weatherRegion": "13",
  "memory": "...",
  "context": { "now": "2026-11-06T07:30:00+09:00", "timeZone": "Asia/Tokyo" },
  "messages": [
    { "role": "user", "content": "おはよう" }
  ]
}
```

- `language`: 会話の言語。キャラが話せなければキャラの言語になる
- `capabilities`: 端末で使える道具 (許可があるものだけ)
- `todayEvents`・`weatherRegion`: 電話の最初のひとことで、設定がオンのときだけ送る。`weatherRegion` は都道府県コード (`01`〜`47`)。天気は WeatherKit から取る
- `messages[].role`: `system` / `user` / `assistant` / `tool`。道具を使ったときは `toolCalls`・`toolCallID` を入れる

```json
{ "type": "message", "message": "おはよう！今日は晴れだって。" }
```

`type` が `toolCall` のときは `calls` に道具の呼び出しが入ります。端末で実行し、結果を `role: tool` で足して呼び直します (`signature` はそのまま返す)。
1 日の回数を超えると 429 です。

## POST: /tts 🔒

キャラの声で読み上げた WAV を返します。声はキャラの設定からサーバが決めます。1 日の文字数を超えると 429 です。

```json
{ "charaID": "com.charalarm.yui", "text": "おはよう！" }
```

## POST: /weather 🔒

地域の今日の天気 (WeatherKit)。アプリのトップに出します。地域は URL に入れるとアクセスログに残るので、ボディで送ります。
サーバは地域ごとに 1 時間キャッシュします。WeatherKit の設定がない環境では 503 です。

```json
{ "region": "13" }
```

```json
{ "region": "13", "conditionCode": "PartlyCloudy", "temperatureMax": 18.2, "temperatureMin": 9.4, "precipitationChance": 0.1 }
```

アプリは `conditionCode` で天気の絵を決めます。画面に出すときは Apple Weather の表記とデータ提供元のページへのリンクを添えます (WeatherKit の利用条件)。

## POST: /webhook/revenuecat

RevenueCat からの通知。`Authorization` ヘッダが SSM に置いた秘密の値と合うときだけ受け付け、user-table の `premiumPlan` を更新します。
