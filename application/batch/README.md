# batch

EventBridge から呼ばれるバッチ。入力の `job` で仕事を分ける。

- job なし (毎分): 今の時刻のアラームを alarm-table から引き、SQS (`voip-push-queue.fifo`) に入れる
- `{"job":"trendNews"}`: X の話題のニュースを取り、Gemini で選んでリソースの `trend-news/ja.json`・`en.json` に置く (`trendnews/`)

構成全体は [docs/system/system.md](../../docs/system/system.md)。

```sh
cd application
make test               # テスト
go fmt ./...
```
