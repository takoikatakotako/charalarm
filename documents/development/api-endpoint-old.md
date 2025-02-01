## Endpoint

charalarm-api のエンドポイント一覧です。



## Admin

### Alarm

ユーザーのアラームを取得する

Path: /api/admin/alarm/{userId}/list  
Header: X-API-VERSION, Authorization  
Response: JsonResponseBean<ArrayList<AlarmResponseBean>>


### Chara

キャラクターを追加する

Path: /api/admin/chara/add
Header: X-API-VERSION, Authorization  
Body: CharaRequestBean
Response: JsonResponseBean<String>


キャラクターを編集する

Path: /api/admin/chara/edit/{charaId}
Header: X-API-VERSION, Authorization  
Body: CharaRequestBean  
Response: JsonResponseBean<String>


キャラクターを削除する

Path: /api/admin/chara/delete/{charaId}
Header: X-API-VERSION, Authorization  
Response: JsonResponseBean<String>


### News

ニュースを追加する

Path: /api/admin/news/add  
Header: X-API-VERSION, Authorization  
Body: NewsRequestBean  
Response: JsonResponseBean<String>


ニュースを編集する

Path: /api/admin/news/edit/{newsId}
Header: X-API-VERSION, Authorization  
Body: NewsRequestBean  
Response: JsonResponseBean<String>


ニュースを削除する
Path: /api/admin/news/delete/{newsId}
Header: X-API-VERSION, Authorization  
Response: JsonResponseBean<String>


### User

ユーザーを取得する

Path: /api/admin/user/list
Header: X-API-VERSION, Authorization  
Response: JsonResponseBean<ArrayList<UserResponseBean>>


ユーザーを退会させる

Path: /api/admin/user/{userId}/withdraw
Header: X-API-VERSION, Authorization
Response: JsonResponseBean<String>


## Alarm

ユーザーのアラームのリストを取得する

Path: /api/alarm/list
Header: X-API-VERSION, Authorization


ユーザーのアラームを追加する

Path: /api/alarm/add


アラームを更新する

Path: /api/alarm/edit/{alarmId}


アラームを削除

Path: /api/alarm/delete/{alarmId}



## Auth

匿名ユーザー新規登録

Path: /api/auth/anonymous/signup


匿名ユーザー退会

Path: /api/auth/anonymous/withdraw



## Chara

キャラクターのリストを取得する

Path: /api/chara/list


charaId からキャラクーターを取得する

Path: /api/chara/{charaId}


charaDomain からキャラクーターを取得する

Path: /api/chara/domain/{charaDomain}


ユーザーキャラクターを設定する

Path: /api/chara/set/{charaDomain}



## News

ニュースのリストを取得する

Method: Post
Path: /api/news/list


## PushToken

iOSのVoipPushTokenを登録する

Method: Post
Path: /api/push-token/ios/voip-push/add


PushTokenを登録する

Method: Post
Path: /api/push-token/ios/push/add


## RequiredVersion

クライアントの動作に必要なバージョンを取得する

Method: Get
Path: /api/required-version
