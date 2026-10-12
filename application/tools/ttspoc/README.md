# ttspoc

Gemini TTS（Vertex AI）の Voice Replication を検証する CLI（#245）。声を作成し、文を合成して WAV を保存する。あわせて、最初の音が届くまでの時間、全体の時間、音声長、概算コストを表にする。

## 前提

- `gcloud auth login` 済みで、対象プロジェクト（既定は sandbox の `sandbox-492513`）の Vertex AI を使えること
- 認証は `gcloud auth print-access-token` のトークンを使う

## 1. 録音を用意する

Voice Replication は **WAV・24kHz・モノラル・16bit** を要求する。macOS 標準の `afconvert` で変換できる。

```bash
afconvert -f WAVE -d LEI16@24000 -c 1 source.m4a source.wav
afconvert -f WAVE -d LEI16@24000 -c 1 consent.m4a consent.wav
```

- `source.wav`: 本人の自然な発話。10〜30 秒、1 人、雑音が少ないもの
- `consent.wav`: 同じ人が同意文を一字一句読み上げたもの。日本語の文面は [Replicate voices](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/text-to-speech/voice-replication) で確認する

録音した音声は個人の声なので、リポジトリには入れない。

## 2. 声を作る

```bash
go run ./tools/ttspoc create-voice -source source.wav -consent consent.wav -name "owner-poc"
```

レスポンスの `id`（`voice_...`）を控える。

## 3. 合成して計測する

```bash
go run ./tools/ttspoc synth -voice voice_xxx -out /tmp/ttspoc
go run ./tools/ttspoc synth -voice voice_xxx -style "明るく元気に、朝起こすように" -text-file lines.txt
```

- Flash と Flash-Lite の両方で合成する（`-models` で変更可）
- `-text-file` は 1 行 1 文。省略すると、時刻・予定・固有名詞を含む組み込みの文を使う
- コストは Gemini API の発表時価格（出力のみ）からの概算。Vertex AI の価格表で確認すること

## 4. 片付け

```bash
go run ./tools/ttspoc list-voices
go run ./tools/ttspoc delete-voice -voice voice_xxx
```
