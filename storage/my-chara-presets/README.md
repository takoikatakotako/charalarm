# 自分のキャラの見た目プリセット

男性3種類・女性7種類、計10種類のアニメ調の立ち絵。1024 × 1536 の透過PNG。
内蔵 `image_gen` で各キャラを個別に作成した。最終プロンプトと画像の SHA-256 は [presets.json](presets.json) に保存している。
画像は `images/` に置く。見た目の名前は選択用のラベルで、ユーザーが付ける名前・性格・声とは独立する。

| プリセット | 画像 | プリセット | 画像 |
|---|---|---|---|
| ひなた | ![ひなた](images/hinata.png) | はると（男性） | ![はると](images/haruto.png) |
| あおい | ![あおい](images/aoi.png) | れん（男性） | ![れん](images/ren.png) |
| あかり | ![あかり](images/akari.png) | そら（男性） | ![そら](images/sora.png) |
| りん | ![りん](images/rin.png) | さくら | ![さくら](images/sakura.png) |
| ゆづき | ![ゆづき](images/yuzuki.png) | るな | ![るな](images/luna.png) |

## 開発環境への登録

```sh
python3 storage/my-chara-presets/register.py
aws sso login --profile charalarm-development-sso
python3 storage/my-chara-presets/register.py --apply
python3 storage/my-chara-presets/register.py --verify
```

引数なしでは画像・内訳・ID・チェックサムの検証だけを行う。
`--apply` は既存の管理APIを使い、開発環境に登録する。認証情報は SSM からメモリ内に取得し、表示・保存しない。
本番環境は変更しない。

`--verify` は読み取りだけを行い、全10件の有効・プリセット設定、アプリのプリセット一覧への掲載、通常一覧に出ないこと、配信画像2枚のチェックサムを確認する。

1. `com.charalarm.preset.<id>` を無効のプリセットとして追加する。
2. 立ち絵を `normal.png` と `thumbnail.png` にアップロードする。
3. `normal` の画像に関連付け、最後に有効にする。
4. 管理APIで有効・プリセットになっていることを再取得して確認する。

途中で失敗した場合は無効のまま残り、再実行で再開できる。有効な既存プリセットは変更しない。
管理画面の「キャラクター → 見た目プリセット」で表示・編集・画像差し替えができる。
追加画像は既存のリソース画面からアップロードし、`normal` に設定する。

## アプリとAPI

- iOS「自分のキャラ」で画像一覧から見た目を選び、名前（50文字まで）・性格や口調（1,000文字まで）・声を個別に設定する。手持ちのVRMも引き続き使える。
- 名前・性格・選んだ声は端末に保存する。画像はプリセットのリソースとして配信する。
- `/chat` の `myChara: { name, personality }` でプリセットの人格を置き換える。通常キャラや無効なプリセットへの上書きは拒否する。
- `/chara/voices` で10種類の声を返す。`/tts` の `voiceID` は公開一覧の声だけを許可する。見た目の声・話し方は引き継がない。
- 声の試聴も認証・既存の利用上限の対象。声を切り替えたり画面を閉じたりすると試聴を止める。
- 既存の保存データに新項目がなくても読める。声を選んでいない既存データは従来の既定の声を使う。
- 用意したプリセットはすべてGemini会話対応。アラームから始まる会話でも端末に保存した設定を使う。録音済みのボイスの声は変更しない。

声の出典: [Google Cloud Gemini TTS](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/text-to-speech/overview)。
声の作成や複製は今回含めず、既存の音声合成で使える声を選ぶ。

## 確認

```sh
cd storage/my-chara-presets
python3 -m unittest -v test_register.py
```

登録順序、失敗時に有効化しないこと、再実行、既存データを上書きしないことを検証する。
APIのテストは `application/api/service/my_chara_test.go` と `application/api/handler/my_chara_test.go`。
