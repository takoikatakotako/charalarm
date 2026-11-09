# DynamoDB

DynamoDB のテーブルと項目です。正は `application/infrastructure/database/*.go` の構造体で、ここはその要約です。
ローカル (Moto) の作り方は `local/createTable.sh`、AWS 上は `terraform/modules/dynamodb` にあります。

サーバに個人情報は置きません。会話の履歴・キャラの記憶・予定の中身・天気の地域は端末にだけあります。

| テーブル | キー | 中身 |
|---|---|---|
| user-table | `userID` | ユーザー、プッシュトークン、プレミアム |
| alarm-table | `alarmID` (GSI: `user-id-index`, `alarm-time-index`, `target-index`) | アラーム |
| chara-table | `charaID` | キャラ |
| chara-tap-line-table | `charaID` + `lineID` | キャラをタップしたときのセリフ |
| news-table | `newsID` | アプリのお知らせ |
| usage-table | `usageKey` (TTL: `expiresAt`) | 会話・音声合成の 1 日の使用量 |


## user-table

```json
{
  "userID": "{UUID}",
  "authToken": "{UUID}",
  "platform": "iOS",
  "premiumPlan": false,
  "premiumPlanEventAt": "{RFC 3339}",
  "createdAt": "{RFC 3339}",
  "updatedAt": "{RFC 3339}",
  "iosPlatformInfo": {
    "pushToken": "{String}",
    "pushTokenSNSEndpoint": "{SNS エンドポイントの ARN}",
    "voIPPushToken": "{String}",
    "voIPPushTokenSNSEndpoint": "{SNS エンドポイントの ARN}"
  }
}
```

- `userID` と `authToken` はアプリが作る UUID。API は Basic 認証 (`userID:authToken`) で使う
- `premiumPlan` は RevenueCat の Webhook (`/webhook/revenuecat`) で更新する


## alarm-table

```json
{
  "alarmID": "{UUID}",
  "userID": "{UUID}",
  "type": "IOS_VOIP_PUSH_NOTIFICATION",
  "target": "{SNS エンドポイントの ARN}",
  "enable": true,
  "name": "{String}",
  "hour": 22,
  "minute": 30,
  "time": "22-30",
  "timeDifference": 9.0,
  "//": "日本の平日 7:30 のアラーム → UTC の日〜木 22:30",
  "charaID": "com.charalarm.yui",
  "charaName": "井上結衣",
  "voiceFileName": "{String}",
  "sunday": true,
  "monday": true,
  "tuesday": true,
  "wednesday": true,
  "thursday": true,
  "friday": false,
  "saturday": false,
  "call": {
    "timeLimit": 60,
    "schedule": true,
    "weather": true,
    "news": false
  }
}
```

- `type`: `IOS_PUSH_NOTIFICATION` か `IOS_VOIP_PUSH_NOTIFICATION`
- `target`: 送り先の SNS エンドポイント。`target-index` で、トークンが変わったときに引き直す
- `hour` / `minute` / 曜日: UTC で持つ。API が端末の時刻 (現地) と `timeDifference` から変換して保存し、返すときに現地に戻す (`application/api/service/converter.go`)
- `time`: `alarm-time-index` 用。`("%02d-%02d", hour, minute)`。バッチが毎分、UTC の今の時刻でこの値を引く
- `timeDifference`: アラームを作った端末の UTC からの時差 (時間)
- `charaID` / `charaName` / `voiceFileName`: ランダムのときは `RANDOM`
- `call`: 電話 (AI 会話) の設定。無いアラーム (古いアプリが作ったもの) は、アプリ共通の設定を使う
    - `timeLimit`: 電話の長さ (秒)。30 / 60 / 90 / 120 / 180 のどれか
    - `schedule` / `weather` / `news`: 電話の最初に、今日の予定・天気・話題のニュースに触れるか
    - 予定の中身や地域は持たない (端末の値を使う)


## chara-table

```json
{
  "charaID": "com.charalarm.yui",
  "enable": true,
  "created_at": "2023-06-03",
  "updated_at": "2023-06-14",
  "name": "井上結衣",
  "description": "{String}",
  "displayOrder": 1,
  "preset": false,
  "profiles": [{ "title": "声優", "name": "{String}", "url": "{URL}" }],
  "expressions": {
    "normal": { "imageFileNames": ["normal.png"], "voiceFileNames": ["{String}"] }
  },
  "calls": [{ "message": "{String}", "voiceFileName": "{String}" }],

  "appearanceType": "vrm",
  "vrmFileName": "yui.vrm",

  "conversationType": "gemini",
  "conversationPrompt": "{人格プロンプト}",
  "conversationLanguages": ["ja", "en"],
  "voicevoxStyleID": 3,
  "voiceProvider": "gemini",
  "geminiVoice": "{声の名前}",
  "geminiVoiceStyle": "{声の調子の指示}",

  "callOpeningPrompt": "{電話の最初のひとことの指示}",
  "callEndingPrompt": "{電話を切るときの指示}",
  "callNoInputEndingPrompt": "{返事が無くて切るときの指示}"
}
```

- `preset`: 「自分のキャラ」の見た目のプリセット。キャラ一覧 (`/chara/list`) とランダムのアラームには出さず、`/chara/presets` で返す。ユーザーは見た目（立ち絵・VRM・手持ちのVRM）、名前、性格、会話の声を端末で設定する。名前・性格は `/chat` の `myChara`、声は `/tts` の `voiceID` で送り、サーバには保存しない。声が未指定の場合と録音ボイスは従来のキャラの設定を使う
- `appearanceType`: `illustration` (立ち絵) か `vrm`。未設定なら立ち絵
- `conversationType`: `none` (アラームだけ) / `voicevox` (端末で合成) / `gemini` (サーバで合成)。未設定なら古い項目から導く
- `conversationLanguages`: 話せる言語。未設定なら日本語だけ。対応している言語は `ja` `en` `zh-Hans` `zh-Hant` `ko` `es` `fr` `de`
- キャラの編集は管理画面から行う。リソース (画像・ボイス・VRM) の置き場は [キャラクター](chara.md)


## chara-tap-line-table

トップでキャラをタップしたときのセリフ。1 行に 1 セリフ。

```json
{
  "charaID": "com.charalarm.yui",
  "lineID": "{UUID}",
  "text": "{String}",
  "voiceFileName": "tap-{lineID}.wav",
  "theme": "morning",
  "language": "ja",
  "when": { "dates": ["12-25"], "hours": [22, 5], "weekdays": [0, 6] }
}
```

- 管理画面で下書きを作り (Gemini)、ボイスを作ってリソースに置く
- `when` の空の項目は条件にしない。`hours` は [開始, 終了) で、開始 > 終了なら日をまたぐ


## news-table

アプリの「お知らせ」。管理画面から作る。

```json
{
  "newsID": "{UUID}",
  "title": "{String}",
  "body": "{String}",
  "registeredAt": "{RFC 3339}"
}
```

話題のニュース (X) はテーブルではなく、バッチが S3 のリソースに `trend-news/ja.json`・`trend-news/en.json` として置きます。


## usage-table

会話 (`/chat`) と音声合成 (`/tts`) の 1 日の使用量。上限を超えると 429 を返す。

```json
{
  "usageKey": "{userID}#{日付}",
  "chat": 12,
  "ttsChars": 3400,
  "expiresAt": 1767225600
}
```

古い日の分は TTL (`expiresAt`) で消えます。
