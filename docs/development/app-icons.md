# アプリアイコン

各環境のデフォルトは、スプラッシュと同じ手書き風の Charalarm ロゴです。「時計を抱える女の子」・井上結衣・時守しおりを、環境ごとの代替アイコンとして登録しています。

アプリ内の「設定 → アプリアイコン」から、Charalarm ロゴ・時計を抱える女の子・井上結衣・時守しおりをプレビュー付きで選べます。切り替えは `UIApplication.setAlternateIconName` を使い、ロゴを選ぶと `nil` を渡してデフォルトに戻します。選択状態は iOS の `alternateIconName` から取得するため、再起動後も実際の設定と一致します。

| 環境 | デフォルト | 代替アイコン | 表示 |
| --- | --- | --- | --- |
| Develop | AppIcon-Logo-Develop | AppIcon-ClockHug-Develop / AppIcon-Yui-Develop / AppIcon-Shiori-Develop | 下部に Develop |
| Staging | AppIcon-Logo-Staging | AppIcon-ClockHug-Staging / AppIcon-Yui-Staging / AppIcon-Shiori-Staging | 下部に Staging |
| Production | AppIcon-Logo-Production | AppIcon-ClockHug-Production / AppIcon-Yui-Production / AppIcon-Shiori-Production | 環境ラベルなし |

アセットは `ios/Charalarm/Assets.xcassets` 内の同名の `.appiconset` にあります。すべて 1024 × 1024 px の不透明 PNG です。

設定画面のプレビューには `AppIconLogoPreview.imageset`、`AppIconClockHugPreview.imageset`、`AppIconYuiPreview.imageset`、`AppIconShioriPreview.imageset` を使います。Production の画像を 256 × 256 px に縮小したもので、ホーム画面の実際のアイコンにはビルドした環境の画像が使われます。

ロゴの元画像は `charalarm-logo.imageset/CharalarmLogo.png`（320 × 93 px）です。ロゴ全体の縦横比と色を保ち、幅 900 px に拡大して白い 1024 × 1024 px の正方形の中央に配置しています。Develop / Staging の環境ラベルは、既存のしおりのアイコン下部をそのまま合成しています。再生成には ImageMagick が必要です。

```bash
bash ios/scripts/generate-logo-icons.sh
```

「時計を抱える女の子」の原本は `AppIcon-ClockHug-Production.appiconset/charalarm-clock-hug-production.png` です。承認済みのクリームベージュ・余白調整版をそのまま登録しています。Develop / Staging は絵全体を上部 824 px に収め、元画像の端の背景を左右に延長してから、下部 200 px に既存と同じ環境ラベルを合成します。女の子や時計が帯で隠れない構成です。派生画像は以下で再生成できます。

```bash
bash ios/scripts/generate-clock-hug-icons.sh
```

`ios/project.yml` の各ターゲットで `ASSETCATALOG_COMPILER_APPICON_NAME` と `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` を指定しています。変更後は `cd ios` で `xcodegen generate` を実行して Xcode プロジェクトを更新します。

結衣の画像は内蔵の画像生成ツールで作成しました。生成元画像とプロンプトは `output/imagegen/inoue-yui-app-icon*` に保存し、アセット登録時に sips で 1024 × 1024 px にリサイズしています。

UI テスト `ScreenTourTests/testAppIconSelection` は、4種類のアイコンへの切り替え、「時計を抱える女の子」の再起動後の保持、ロゴへの復帰を確認します。Debug ビルド限定の起動引数 `--ui-test-settings` で設定画面を直接開き、起動時の API 確認やログインに依存させていません。
