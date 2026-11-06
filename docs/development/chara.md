# キャラクター

キャラクターの画像は [GoogleDrive](https://drive.google.com/drive/folders/1A4Rrh5q8ufCGUdfPfA4NJAn8838ZtHEx?usp=sharing)
に格納されています。（要アクセス権付与）
テーブルの作り方は `local/createTable.sh`、項目は [DynamoDB](dynamodb.md) にあります。キャラの追加・編集とリソースのアップロードは管理画面から行います。


## キャラリソース

リソースは S3 (`resource.<環境のドメイン>`) に置き、CloudFront で配る。
`storage/resources/` は development の S3 の写しで、`storage/Makefile` で環境のあいだを同期する。
今は管理画面からアップロードするのが基本。

- {CharaID}/
    - **thumbnail.png** (必須)
    - normal.png, smile.png, ... (表情の立ち絵)
    - **self-introduction.caf** (必須)
    - *.caf (アラームのボイス)
    - *.vrm (3D の見た目。`appearanceType` が `vrm` のキャラ)
    - tap-<lineID>.wav (タップのセリフのボイス)

API はファイル名にリソースの URL を付けて返す (`https://<リソース>/<CharaID>/<ファイル名>`)。

話題のニュースは、キャラとは別に `trend-news/ja.json`・`trend-news/en.json` に置く。


## エラー用

エラー用にファイルを用意している

- com.charalarm.error
  - voices
    - error.caf
  
