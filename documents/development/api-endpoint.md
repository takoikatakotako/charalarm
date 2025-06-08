# Charalarm API

APIのエンドポイントとレスポンス一覧です。

## Develop
オリジン: [https://charalarm.sandbox.swiswiswift.com](https://charalarm.sandbox.swiswiswift.com)
リソース: [https://resource.charalarm.sandbox.swiswiswift.com/com.charalarm.yui/thumbnail.png](https://resource.charalarm.sandbox.swiswiswift.com/com.charalarm.yui/thumbnail.png)
API: [https://api.charalarm.sandbox.swiswiswift.com/healthcheck](https://api.charalarm.sandbox.swiswiswift.com/healthcheck)

## Staging
オリジン: [https://charalarm.swiswiswift.com](https://charalarm.swiswiswift.com)
リソース: [https://resource.charalarm.swiswiswift.com/com.charalarm.yui/thumbnail.png](https://resource.charalarm.swiswiswift.com/com.charalarm.yui/thumbnail.png)
API: [https://api.charalarm.swiswiswift.com/healthcheck](https://api.charalarm.swiswiswift.com/healthcheck)

# Production
オリジン: [https://charalarm.com](https://charalarm.com)
リソース: [https://resource.charalarm.com/com.charalarm.yui/thumbnail.png](https://resource.charalarm.com/com.charalarm.yui/thumbnail.png)
API: [https://api2.charalarm.com/healthcheck](https://api2.charalarm.com/healthcheck)


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





```
$ curl http://localhost:8080/healthcheck/ | jq
```

```
{
  "message": "Healthy!"
}
```


```
curl -X POST http://localhost:8080/user/signup/ \
    -H 'Content-Type: application/json' \
    -d '{"userID":"20f0c1cd-9c2a-411a-878c-9bd0bb15dc35","authToken":"038a5e28-15ce-46b4-8f46-4934202faa85","authToken":"038a5e28-15ce-46b4-8f46-4934202faa85", "platform":"iOS"}' | jq
```

```
{
  "message": "Sign Up Success!"
}
```


```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST http://localhost:8080/user/withdraw/ \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" | jq
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


```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X GET http://localhost:8080/user/info/ \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" | jq
```


```
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


```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST http://localhost:8080/alarm/add/ \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" \
    -d '{"alarm":{"alarmID":"45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7","userID":"20f0c1cd-9c2a-411a-878c-9bd0bb15dc35","type":"IOS_PUSH_NOTIFICATION","enable":true,"name":"alarmName","hour":8,"minute":30,"charaID":"charaID","charaName":"charaName","voiceFileName":"voiceFileName","sunday":true,"monday":false,"tuesday":true,"wednesday":false,"thursday":true,"friday":false,"saturday":true}}' | jq
```

```json
{
  "message": "Add Alarm Success!"
}
```




```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X GET http://localhost:8080/alarm/list/ \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" | jq
```

```
[
  {
    "alarmID": "45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7",
    "userID": "20f0c1cd-9c2a-411a-878c-9bd0bb15dc35",
    "type": "IOS_PUSH_NOTIFICATION",
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




```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST http://localhost:8080/alarm/edit/ \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" \
    -d '{"alarm":{"alarmID":"45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7","userID":"20f0c1cd-9c2a-411a-878c-9bd0bb15dc35","type":"IOS_VOIP_PUSH_NOTIFICATION","enable":true,"name":"alarmName","hour":8,"minute":30,"charaID":"charaID","charaName":"charaName","voiceFileName":"voiceFileName","sunday":true,"monday":false,"tuesday":true,"wednesday":false,"thursday":true,"friday":false,"saturday":true}}' | jq
```

```json
{
  "message": "Edit Alarm Success!"
}
```



```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST http://localhost:8080/alarm/delete/ \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" \
    -d '{"alarmID":"45cd0ab2-941c-4015-9a0f-d49b2b3fb4a7"}' | jq
```

```json
{
  "message": "Delete Alarm Success!"
}
```




```
curl -X GET http://localhost:8080/chara/list/ \
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



```
curl -X GET http://localhost:8080/chara/id/com.charalarm.yui/ \
    -H 'Content-Type: application/json' | jq
```


```
{
  "charaID": "com.charalarm.yui",
  "enable": true,
  "name": "井上結衣",
  "createdAt": "2023-06-03",
  "updatedAt": "2023-06-14",
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
      "fileURL": "http://localhost:4566/com.charalarm.yui/normal.png"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-1.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-4.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-5.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/smile.png"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-2.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-3.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/confused.png"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-5.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-12.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-13.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-14.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-15.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-16.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-17.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-18.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-19.caf"
    },
    {
      "fileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-20.caf"
    }
  ],
  "expressions": {
    "confused": {
      "imageFileURLs": [
        "http://localhost:4566/com.charalarm.yui/confused.png"
      ],
      "voiceFileURLs": [
        "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-5.caf",
        "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-12.caf",
        "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-13.caf",
        "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-14.caf"
      ]
    },
    "normal": {
      "imageFileURLs": [
        "http://localhost:4566/com.charalarm.yui/normal.png"
      ],
      "voiceFileURLs": [
        "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-1.caf",
        "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-4.caf",
        "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-5.caf"
      ]
    },
    "smile": {
      "imageFileURLs": [
        "http://localhost:4566/com.charalarm.yui/smile.png"
      ],
      "voiceFileURLs": [
        "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-2.caf",
        "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-3.caf"
      ]
    }
  },
  "calls": [
    {
      "message": "もしもし、起きる時間だよ",
      "voiceFileName": "com-charalarm-yui-15.caf",
      "voiceFileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-15.caf"
    },
    {
      "message": "おはよう、今日もいい天気だよ",
      "voiceFileName": "com-charalarm-yui-16.caf",
      "voiceFileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-16.caf"
    },
    {
      "message": "もしもし、昨日は夜遅くまで起きてたのかな?",
      "voiceFileName": "com-charalarm-yui-17.caf",
      "voiceFileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-17.caf"
    },
    {
      "message": "もしもし、まだ寝てるの?",
      "voiceFileName": "com-charalarm-yui-18.caf",
      "voiceFileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-18.caf"
    },
    {
      "message": "あっ、もしもし。起こしちゃった？",
      "voiceFileName": "com-charalarm-yui-19.caf",
      "voiceFileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-19.caf"
    },
    {
      "message": "もしもーし、お疲れ様",
      "voiceFileName": "com-charalarm-yui-20.caf",
      "voiceFileURL": "http://localhost:4566/com.charalarm.yui/com-charalarm-yui-20.caf"
    }
  ]
}
```




```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST http://localhost:8080/push-token/ios/push/add/ \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" \
    -d '{"pushToken":"78e1c441fece443abaa519b697b297e1"}' | jq
```

```json
{
  "message": "Hello!"
}
```




```
BASIC_AUTH_HEADER=$(echo -n 20f0c1cd-9c2a-411a-878c-9bd0bb15dc35:038a5e28-15ce-46b4-8f46-4934202faa85 | base64)
curl -X POST http://localhost:8080/push-token/ios/voip-push/add/ \
    -H 'Content-Type: application/json' \
    -H "Authorization: Basic ${BASIC_AUTH_HEADER}" \
    -d '{"pushToken":"78e1c441fece443abaa519b697b297e1"}' | jq
```

```json
{
  "message": "Hello!"
}
```





aws --endpoint-url=http://localhost:4566 dynamodb list-tables


aws --endpoint-url=http://localhost:4566 --region ap-northeast-1 dynamodb create-table \
    --table-name user-table \
    --attribute-definitions AttributeName=userID,AttributeType=S \
    --key-schema AttributeName=userID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1