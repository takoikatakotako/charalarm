# CharalarmBackend

## 概要

Charalarm は2次元のキャラクターに起こされたい！というtakoikatakotakoの思いを叶えてお金も稼ぐために作る個人開発のモバイルアプリです。 ユーザーはモーニングコールをして欲しいキャラクターをアプリ内で選択しアラームをセットします。 アラームをセットした時間に電話に女の子から電話がかかってきて幸せな起床を実現できます。

またキャラクターは同人ゲーム界隈の人から素材を頂こうと思っています。 同人ゲームサークルの人は既存の素材などからアラームアプリを作ることができる、小野はアプリ内にキャラクターが増えて幸せ。というWinWinの関係になるのが目標です。


## 現行アーキテクチャ

Charalarm の現行のアーキテクチャです。 
お金がないのでRDS, SNS, SSQ, S3だけ使って、API, Batch, Worker はConohaVPSに詰め込んでいます。

![Architecture](document/image/current-architecture.png)


## 新アーキテクチャ

Charalarmの新しいアーキテクチャです。
現行アーキテクチャではサービスの維持手数料が高い & サーバー管理が面倒なのでサーバーレス中心の構成にしました。

![Architecture](document/image/infra-architecture.png)


## ドキュメント

- [インフラのアーキテクチャーについて](document/infra-architecture.md)
- [アプリケーションのアーキテクチャーについて](document/app-architecture.md)
- [APIのエンドポイントについて](document/api-endpoint.md)
- [Localstackについて](document/localstack.md)
- [証明書などのアップデートについて](document/update.md)
- [DynamoDBについて](document/dynamodb.md)
- [SQSについて](document/sqs.md)
- [キャラクターについて](document/chara.md)
- [キャラクターのリソースについて](document/chara-resource.md)
