# worker

SQS (`voip-push-queue.fifo`) のメッセージを受け取り、SNS で VoIP プッシュを送る。中身は [docs/development/sqs.md](../../docs/development/sqs.md)。

構成全体は [docs/system/system.md](../../docs/system/system.md)。

```sh
cd application
make test               # テスト
go fmt ./...
```
