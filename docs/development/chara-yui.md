# 井上結衣

Charalarmのマスコットキャラクターです。

### CharaID

com.charalarm.yui

### 3D モデル（VRM）

同梱モデルは `ios/Charalarm/Resource/com.charalarm.yui/yui.vrm`。
テクスチャは 4 枚とも 2048×2048 の JPEG にし、ファイルサイズを 21,788,704 → 10,940,040 bytes に軽量化している。
RGBA8 とミップマップを想定したテクスチャの GPU 使用量は約 341 MiB → 約 85 MiB（モデルや描画バッファなどは別）。骨格・表情・揺れ物・マテリアル設定は元のモデルを保持する。

モデルを更新するときは、macOS の `sips` を使う次のコマンドでテクスチャを縮小できる。
透明度がある画像は PNG を保ち、不透明な画像は JPEG 品質 90 で保存する。入力と出力は別のパスにする。

```bash
python3 ios/scripts/optimize-vrm-textures.py original.vrm optimized.vrm
node --test ios/scripts/tests/texture-limit.test.mjs
python3 -m unittest discover -s ios/scripts/tests
```

ビューアも、GPU への初回アップロード前にテクスチャの長辺を 2048 以下（GPU の制限がより小さければその値）に縮める。
端末にキャッシュされた旧モデルにも効くが、読み込み時の負荷を下げるため、配信・同梱するモデル自体も軽量化する。

`VRMModelRepository` は同じファイル名の同梱モデルを優先し、なければダウンロード済みキャッシュを使う。
S3 の `yui.vrm` だけを上書きしても、既存アプリの同梱版・キャッシュは更新されない。同梱版・ビューアの修正はアプリの再配布が必要で、ダウンロード版の更新はサーバで別のファイル名にする。
配信モデルを差し替える際は、development の実機でトップ・会話画面の表示と表情を確認してから staging / production に反映する。

### description

井上結衣です。プログラマーとして働いていてこのアプリを作っています。このアプリをたくさん使ってくれると嬉しいです、よろしくね！

### profiles

| title    | name   | url                                                                    |
|----------|--------|------------------------------------------------------------------------|
| イラストレーター | さいもん   | [https://twitter.com/simon_ns](https://twitter.com/simon_ns)           |
| 声優       | Mai    | [https://twitter.com/mai_mizuiro](https://twitter.com/mai_mizuiro )    |
| スクリプト    | 小旗ふたる！ | [https://twitter.com/Kass_kobataku](https://twitter.com/Kass_kobataku) |

### calls

| message               | voice                    |
|-----------------------|--------------------------|
| もしもし、起きる時間だよ          | com-charalarm-yui-15.caf |
| おはよう、今日もいい天気だよ        | com-charalarm-yui-16.caf |
| もしもし、昨日は夜遅くまで起きてたのかな? | com-charalarm-yui-17.caf |
| もしもし、まだ寝てるの?          | com-charalarm-yui-18.caf |
| あっ、もしもし。起こしちゃった？      | com-charalarm-yui-19.caf |
| もしもーし、お疲れ様            | com-charalarm-yui-20.caf |

### expressions

**normal**

images

- normal.png

voices

- com-charalarm-yui-1.caf
- com-charalarm-yui-4.caf
- com-charalarm-yui-5.caf

**smile**

images

- smile.png

voices

- com-charalarm-yui-2.caf
- com-charalarm-yui-3.caf

**confused**

images

- confused.png

voices

- com-charalarm-yui-5.caf"
- com-charalarm-yui-12.caf
- com-charalarm-yui-13.caf
- com-charalarm-yui-14.caf

### DDL

[com.charalarm.yui.json](chara-resource/com.charalarm.yui.json) を使用。

```
aws dynamodb put-item \
    --table-name chara-table \
    --item file://chara-resource/com.charalarm.yui.json \
    --profile {PROFILE}
```
