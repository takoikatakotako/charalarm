# iOS

`ios/` にある iOS アプリです。SwiftUI、iOS 18 以上。

## セットアップ

ツールは [Mint](https://github.com/yonaskolb/Mint) で入れます (`ios/Mintfile`: XcodeGen, SwiftLint, R.swift, LicensePlist)。
ライブラリは Swift Package Manager で、`project.yml` に書いてあります (CocoaPods は使っていません)。

```sh
brew install mint
cd ios
mint bootstrap
make setup-voicevox            # VOICEVOX (ずんだもんの声) を S3 から取る。AWS の SSO ログインが要る
mint run xcodegen generate     # Charalarm.xcodeproj を作る (.xcodeproj は git に入れない)
open Charalarm.xcodeproj
```

`project.yml` やファイルの追加・削除をしたら、`xcodegen generate` をやり直します。

## スキーム

| スキーム | Bundle ID | API |
|---|---|---|
| Develop | com.swiswiswift.sandbox.charalarm | api.charalarm-development.swiswiswift.com |
| Staging | com.charalarm.staging | api.charalarm-staging.swiswiswift.com |
| Production | com.swiswiswift.CharacterAlarm | api3.charalarm.com |

API とリソースの URL は `project.yml` の `API_ENDPOINT`・`RESOURCE_ENDPOINT` です。

## つくり

- 画面は `View/<画面>/` に、`〇〇View` (見た目) と `〇〇ViewState` (状態と処理、`@Observable`) を置く
- 通信・端末の機能は `Repository/` (API、Keychain、UserDefaults、カレンダー、VRM のキャッシュ、会話、音声合成など)
- データの形は `Entity/` (API のリクエスト・レスポンスは `Entity/Request`・`Entity/Response`)
- 文言は `Localizable.xcstrings` (String Catalog)

### 電話 (着信から会話まで)

1. VoIP プッシュを受けて (`AppDelegate`)、CallKit で着信を出す。プッシュの中身は `[String: String]` で、アラームの電話の設定 (`callTimeLimit` など) もここで受け取る (`CallSettings(payload:)`)
2. 電話を取ると `ConversationView` で会話を始める。最初のひとことで、設定に応じて今日の予定・天気・話題のニュースに触れる
3. 返事は `/chat` から、声は VOICEVOX (端末) か `/tts` (Gemini) から作る。聞き取りは端末の音声認識
4. 設定した長さになったら、キャラが話をまとめて電話を切る

会話の履歴・キャラの記憶・予定の中身・天気の地域は端末にだけ置きます。

### VRM

VRM のキャラは `CharaVRMView` (WKWebView) で `VRMViewer/` の three-vrm を動かして表示します。
表情・瞬き・口パクは `viewer.js` にあります。口パクは、声を流す直前に音の大きさから口の開き具合を作り（`VRMMouthTrack`）、ビューアにまとめて渡しています。モデルの軽量化は [結衣](chara-yui.md) を参照。

## Lint とテスト

```sh
cd ios
mint run swiftlint --strict    # CI と同じ。警告もエラーになる
```

PR では GitHub Actions (`test-ios.yml`) が SwiftLint と、VRM のスクリプトのテスト (`ios/scripts/tests`) を走らせます。アプリのビルドは CI では走らないので、手元で確かめます。

Simulator でビルドするときは、署名なしだと Firebase のキーチェーンで失敗するので、ad-hoc 署名 (`CODE_SIGN_IDENTITY=-`) でビルドします。

## ライセンス表記の更新

```sh
cd ios
mint run LicensePlist license-plist --output-path Charalarm/Settings.bundle
```
