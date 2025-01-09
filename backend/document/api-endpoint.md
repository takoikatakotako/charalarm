# Charalarm API

APIのエンドポイントとレスポンス一覧です。


# /

## GET: /healthcheck

ヘルスチェックに使用するエンドポイントです。

```
$ curl https://api.sandbox.swiswiswift.com/healthcheck | jq
```

```
{
  "message": "Healthy!"
}
```

# /user

## POST: /user/signup

ユーザーの新規登録を行うエンドポイントです。
`userID`, `authToken` はクライアント側で生成したUUIDを使用します。
生成したUUIDはクライアント側のKeyChainなどで保持します。

```
curl -X POST https://api.sandbox.swiswiswift.com/user/signup \
    -H 'Content-Type: application/json' \
    -d '{"userID":"20f0c1cd-9c2a-411a-878c-9bd0bb15dc35","authToken":"038a5e28-15ce-46b4-8f46-4934202faa85"}' | jq
```

成功時のレスポンスです。登録済みのユーザーでもこのレスポンスを返します。

```
{
  "message": "Sign Up Success!"
}
```

失敗時のレスポンスです。`userID`, `authToken` の形式がUUIDではない場合や予期せぬエラーが起きた場合はこのレスポンスを返します。

```
{
  "message": "Sign Up Failure..."
}
```


## POST: /user/withdraw

ユーザの退会時に使用するエンドポイントです。

```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST https://api.sandbox.swiswiswift.com/user/withdraw \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}"
```

```
{
  "message": "Withdraw Success!"
}
```

```
{
  "message": "Withdraw Failure..."
}
```


## POST: /user/info

ユーザーの情報を取得するエンドポイントです。

```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST https://api.sandbox.swiswiswift.com/user/info \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" | jq
```

```
{
  "userID": "20f0c1cd-9c2a-411a-878c-9bd0bb15dc35",
  "authToken": "20**********************************",
  "iosVoIPPushTokens": {
    "token": "",
    "snsEndpointArn": ""
  },
  "iosPushTokens": {
    "token": "",
    "snsEndpointArn": ""
  }
}
```

# alarm

## POST: /alarm/list

```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST https://api.sandbox.swiswiswift.com/alarm/list \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" | jq
```

```json
[
  {
    "alarmID": "45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7",
    "userID": "20f0c1cd-9c2a-411a-878c-9bd0bb15dc35",
    "type": "VOIP_NOTIFICATION",
    "enable": true,
    "name": "alarmName",
    "hour": 8,
    "minute": 30,
    "timeDifference": 0,
    "charaID": "charaID",
    "charaName": "charaName",
    "voiceFileName": "voiceFileName",
    "sunday": true,
    "monday": false,
    "tuesday": true,
    "wednesday": false,
    "thursday": true,
    "friday": false,
    "saturday": true
  }
]
```

## POST: /alarm/add

アラームを追加します。

```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST https://api.sandbox.swiswiswift.com/alarm/add \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" \
    -d '{"alarm":{"alarmID":"45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7","userID":"20f0c1cd-9c2a-411a-878c-9bd0bb15dc35","type":"VOIP_NOTIFICATION","enable":true,"name":"alarmName","hour":8,"minute":30,"charaID":"charaID","charaName":"charaName","voiceFileName":"voiceFileName","sunday":true,"monday":false,"tuesday":true,"wednesday":false,"thursday":true,"friday":false,"saturday":true}}' | jq
```

```json
{
  "message": "Add Alarm Success!"
}
```


## POST: /alarm/edit

```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST https://api.sandbox.swiswiswift.com/alarm/edit \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" \
    -d '{"alarm":{"alarmID":"45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7","userID":"20f0c1cd-9c2a-411a-878c-9bd0bb15dc35","type":"VOIP_NOTIFICATION","enable":true,"name":"alarmName","hour":8,"minute":30,"charaID":"charaID","charaName":"charaName","voiceFileName":"voiceFileName","sunday":true,"monday":false,"tuesday":true,"wednesday":false,"thursday":true,"friday":false,"saturday":true}}' | jq
```

```json
{
  "message": "Edit Alarm Success!"
}
```

## POST: /alarm/delete

アラームを削除します。

```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST https://api.sandbox.swiswiswift.com/alarm/delete \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" \
    -d '{"alarmID":"45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7"}' | jq
```

```json
{
  "message": "Delete Alarm Success!"
}
```

# chara

## GET: /chara/list

キャラ一覧を取得します。

```
curl -X GET https://api.sandbox.swiswiswift.com/chara/list \
    -H 'Content-Type: application/json' | jq
```

```json
[
  {
    "charaID": "com.charalarm.yui",
    "charaEnable": false,
    "charaName": "井上結衣",
    "charaDescription": "井上結衣です。プログラマーとして働いていてこのアプリを作っています。このアプリをたくさん使ってくれると嬉しいです、よろしくね！",
    "charaProfiles": [],
    "charaResource": {
      "images": [
        "thumbnail.png",
        "normal.png"
      ],
      "voices": [
        "self-introduction.caf",
        "com-charalarm-yui-0.caf"
      ]
    },
    "charaExpression": {
      "normal": {
        "images": [
          "normal.png"
        ],
        "voices": [
          "com-charalarm-yui-1.caf"
        ]
      }
    },
    "charaCall": {
      "voices": [
        "com-charalarm-yui-15.caf",
        "com-charalarm-yui-16.caf"
      ]
    }
  }
]
```

## GET: /chara/id/{charaID}

特定のキャラを取得します。

```
curl -X GET https://api.sandbox.swiswiswift.com/chara/id/com.charalarm.yui \
    -H 'Content-Type: application/json' | jq
```

```json
{
  "charaID": "com.charalarm.yui",
  "enable": true,
  "name": "井上結衣",
  "description": "井上結衣です。プログラマーとして働いていてこのアプリを作っています。このアプリをたくさん使ってくれると嬉しいです、よろしくね！",
  "profiles": [
    {
      "title": "イラストレーター",
      "name": "さいもん",
      "url": "https://twitter.com/simon_ns"
    },
    {
      "title": "声優",
      "name": "Mai",
      "url": "https://twitter.com/mai_mizuiro"
    },
    {
      "title": "スクリプト",
      "name": "小旗ふたる！",
      "url": "https://twitter.com/Kass_kobataku"
    }
  ],
  "resources": [
    {
      "directoryName": "image",
      "fileName": "confused.png"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-5.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-12.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-13.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-14.caf"
    },
    {
      "directoryName": "image",
      "fileName": "normal.png"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-1.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-4.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-5.caf"
    },
    {
      "directoryName": "image",
      "fileName": "smile.png"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-2.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-3.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-15.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-16.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-17.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-18.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-19.caf"
    },
    {
      "directoryName": "voice",
      "fileName": "com-charalarm-yui-20.caf"
    }
  ],
  "expressions": {
    "confused": {
      "images": [
        "confused.png"
      ],
      "voices": [
        "com-charalarm-yui-5.caf",
        "com-charalarm-yui-12.caf",
        "com-charalarm-yui-13.caf",
        "com-charalarm-yui-14.caf"
      ]
    },
    "normal": {
      "images": [
        "normal.png"
      ],
      "voices": [
        "com-charalarm-yui-1.caf",
        "com-charalarm-yui-4.caf",
        "com-charalarm-yui-5.caf"
      ]
    },
    "smile": {
      "images": [
        "smile.png"
      ],
      "voices": [
        "com-charalarm-yui-2.caf",
        "com-charalarm-yui-3.caf"
      ]
    }
  },
  "calls": [
    {
      "message": "井上結衣さんのボイス15",
      "voice": "com-charalarm-yui-15.caf"
    },
    {
      "message": "井上結衣さんのボイス16",
      "voice": "com-charalarm-yui-16.caf"
    },
    {
      "message": "井上結衣さんのボイス17",
      "voice": "com-charalarm-yui-17.caf"
    },
    {
      "message": "井上結衣さんのボイス18",
      "voice": "com-charalarm-yui-18.caf"
    },
    {
      "message": "井上結衣さんのボイス19",
      "voice": "com-charalarm-yui-19.caf"
    },
    {
      "message": "井上結衣さんのボイス20",
      "voice": "com-charalarm-yui-20.caf"
    }
  ]
}
```

# push-token

## POST: /push-token/ios/push/add


## POST: /push-token/ios/voip-push/add


# news

## GET: /news/list



## エラーメッセージ





curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"userId": "okki-", "authToken":"password"}' \
  https://api.sandbox.swiswiswift.com/user/signup/anonymous







https://99byleidca.execute-api.ap-northeast-1.amazonaws.com/production


https://api.sandbox.swiswiswift.com/user/signup/anonymous



aws lambda list-functions --profile sandbox | jq


aws lambda update-function-code --function-name healthcheck-get-function --s3-bucket application.charalarm.sandbox.swiswiswift.com --s3-key 0.0.1/healthcheck.zip --profile sandbox

