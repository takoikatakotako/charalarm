## 諸々のアップデート

### プッシュ証明書

[developer.apple.com](https://developer.apple.com/) にアクセス。
[Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list) にアクセス。

#### VoIPの証明書更新

- [VoIP Services Certificate] を選択
- [Upload a Certificate Signing Request] で [CertificateSigningRequest.certSigningRequest] をアップロードする
- 証明書をダウンロードする
- 証明書を開く。昔のやつはすでに書き出してあるのであれば消してしまっても良いかもしれない。
- .p12として書き出す。パスワードが求められるのでメモする。（今回はvoip-staging.p12として書き出した）
- 以下のコマンドで証明書と鍵を取り出す。メモしたパスワードを使用する。
- 生成したファイルをTerraformに託す

```
openssl pkcs12 -in voip-staging.p12 -nodes -nokeys -out voip-staging-certificate.pem
openssl pkcs12 -in voip-staging.p12 -nodes -nocerts -out voip-staging-privatekey.pem
```

#### プッシュ通知証明書更新

- [Apple Push Notification service SSL (Sandbox & Production)]
- [Upload a Certificate Signing Request] で [CertificateSigningRequest.certSigningRequest] をアップロードする
- 証明書をダウンロードする
- 証明書を開く。昔のやつはすでに書き出してあるのであれば消してしまっても良いかもしれない。
- .p12として書き出す。パスワードが求められるのでメモする。（今回はpush-staging.p12として書き出した）
- 以下のコマンドで証明書と鍵を取り出す。メモしたパスワードを使用する。
- 生成したファイルをTerraformに託す

```
openssl pkcs12 -in push-staging.p12 -nodes -nokeys -out push-staging-certificate.pem
openssl pkcs12 -in push-staging.p12 -nodes -nocerts -out push-staging-privatekey.pem
```