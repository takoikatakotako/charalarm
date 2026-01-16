# キャラクター

キャラクターの画像は [GoogleDrive](https://drive.google.com/drive/folders/1A4Rrh5q8ufCGUdfPfA4NJAn8838ZtHEx?usp=sharing)
に格納されています。（要アクセス権付与）
DDLは [https://github.com/takoikatakotako/charalarm-backend/blob/develop/localstack/createTable.sh](https://github.com/takoikatakotako/charalarm-backend/blob/develop/localstack/createTable.sh) にも格納されています。


 ## キャラリソース

キャラリソースは以下のようなディレクトリ構造をしている。
`thumbnail.png`, `self-introduction.caf` は必須ファイル。

- {CharaID}
  - images
    - **thumbnail.png**
    - normal.png
    - smile.png
    - ...
  - voices
    - **self-introduction.caf**
    - voice.caf
    - ...


## エラー用

エラー用にファイルを用意している

- com.charalarm.error
  - voices
    - error.caf
  
