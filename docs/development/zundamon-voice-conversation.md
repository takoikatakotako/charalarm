# ずんだもん音声会話機能 移植プラン

## 背景 / 目的

Charalarm を「ずんだもんがモーニングコールで起こしてくれる」だけでなく、
**着信を取ったらそのままずんだもんとリアルタイム音声会話できる**アプリへ発展させる。

- 既存の多キャラ・アラーム・課金基盤は残したまま、**アラームに会話機能を上乗せ**する方針。
- 会話は**リアルタイム双方向**（自分が話す → 返答が音声で返る）。まずはターン制で成立させる。
- 姉妹プロジェクト **ZunTalk**（`takoikatakotako/ZunTalk`, App Store v1.7.0）が
  この会話機能を既に製品として実装済みのため、**ゼロから作らず ZunTalk から移植・合体**する。

## なぜ地続きか（既存資産との噛み合わせ）

Charalarm と ZunTalk は補完関係にある。★は両方に存在する。

| Charalarm が既に持つ | ZunTalk が持つ |
|---|---|
| アラーム時刻スケジューリング (EventBridge→Batch→SQS→Worker→SNS→VoIP Push) | 端末内リアルタイム音声合成 (VOICEVOX CORE) |
| CallKit「着信」導線 ★ | STT (iOS Speech, ja-JP) |
| DynamoDB ユーザー / 課金基盤 | 会話ループ (ターン制 + チャンク先読み再生) |
| ずんだもんキャラ・クレジット画面 ★ | LLM 連携 (プロバイダ差替可能) / CallKit「ずんだもんから着信」★ |

**「アラーム発火 → VoIP Push → CallKit 着信 → 取る」までは Charalarm に既にある。**
現状は着信を取ると事前生成した `.caf` クリップを再生するだけ。
**ここを ZunTalk の会話ループに差し替える**のが本移植の核心。

## ライセンス確認結果（着手前提クリア）

- **商用利用 OK**（ずんだもん音源・VOICEVOX 本体とも「商用・非商用ともに利用可」）。
- **クレジット表記が必須**：文言例「VOICEVOX:ずんだもん」。アプリ紹介画面 or アプリ内クレジット画面に記載。
  無しでやるなら 1 キャラ 40 万円契約 → 表記する一択。
- Charalarm・ZunTalk とも**クレジット画面を既に実装済み**なので、そのまま流用可。
  - Charalarm: `ios/Charalarm/View/Licence/LicenceView.swift`
  - ZunTalk（より充実）: `ios/ZunTalk/Screens/Config/License/LicenseView.swift`
- 再配布の注意：端末内方式は VOICEVOX CORE(MIT) と**ずんだもん音源モデルをアプリバイナリに同梱＝再配布**する形。
  CORE は組込み用に配布されており可能だが、音源利用規約の遵守（クレジット）が条件。
- 禁止事項（公序良俗違反 / 政治・宗教 / 情報商材 / 虚偽拡散 / 風俗 / 反社）は本用途では問題なし。

参照: <https://voicevox.hiroshiba.jp/term/> / <https://zunko.jp/con_ongen_kiyaku.html>

## 移植対象（ZunTalk → Charalarm）

いずれも `takoikatakotako/ZunTalk` の iOS ディレクトリ配下。

| 部品 | ZunTalk のファイル | メモ |
|---|---|---|
| 端末内 TTS 本体 | `Repository/TextToSpeech/VoicevoxRepository.swift` | `voicevox_synthesizer_tts` を呼び WAV を返す。ずんだもん = `styleId = 3` の 1 行 |
| TTS プロトコル/エラー | `Repository/TextToSpeech/TextToSpeechRepository.swift`, `.../Error/VoicevoxError.swift` | |
| ネイティブ資産 | `ios/Voicevox/voicevox_core.xcframework`, `voicevox_onnxruntime.xcframework`, `vvms/0.vvm`(~58MB), Open JTalk 辞書 | **git 管理外・S3 配信**（`Makefile setup-voicevox` が `s3://zuntalk-resources/` から同期）。この配信設計も流用 |
| 会話ループ | `Screens/Call/CallViewModel.swift` + `CallViewModel+SpeechRecognition.swift` | ターン制。2 秒無音で発話終了、最大 3 リトライ、会話上限 120s |
| チャンク再生 | `Screens/Call/TextChunker.swift` | `。！？` 区切りで合成しながら再生しレイテンシ隠蔽。次チャンクを並列合成 |
| 状態機械 / UI | `Screens/Call/CallStatus.swift`, `CallView.swift` | idle→initializingVoiceVox→…→playingVoice→recognizingSpeech→…→ended |
| STT | iOS Speech (`SFSpeechRecognizer` ja-JP) + `AVAudioEngine` タップ | Whisper 不要・端末内・無料 |
| LLM 抽象化 | `Repository/TextGeneration/TextGenerationRepositoryFactory.swift` ほか | プロバイダ差替の口。下記参照 |
| ずんだもんペルソナ | `CallViewModel.swift:26-36`（systemPrompt 等） | 会話用の人格プロンプト |

## アーキテクチャ設計判断

### 1. 音声合成は端末内（サーバレス TTS）
ZunTalk 同様、VOICEVOX CORE を xcframework として端末内に組み込む。TTS サーバ不要・低レイテンシ。
Charalarm 側は現状エンジンを持たず `.caf` 再生のみなので、新規に CORE 連携を追加する。

### 2. LLM はプロバイダ差替可能・デフォルト OpenAI
- ZunTalk の `TextGenerationRepositoryFactory` を踏襲し、**プロバイダを差し替えられる抽象**を維持。
- **デフォルトは OpenAI (`gpt-4o-mini`)**（実装例が多く手堅い）。将来 Claude / Gemini に差替可能な口を残す。
- **API キーは端末に置かない**：Charalarm backend (Go/Lambda) に `/chat` エンドポイントを新設し、
  サーバ側でキーを保持（ZunTalk の AWS Lambda chat 実装 `backend/handler/chat.go`, `backend/service/openai.go` を参考）。

### 3. `.vvm` モデル配布
`.vvm`(~58MB) + xcframework は容量が大きい。**アプリ同梱**（App Store サイズ +60MB 前後）か
**初回オンデマンド DL** かを決める。まず PoC は同梱で進め、リリース前に判断。

### 4. 最小 iOS バージョン
Charalarm は iOS 16+、ZunTalk は **iOS 18.0**。VOICEVOX CORE / iOS Speech 周りの要件次第で
**iOS 18 への引き上げ**が必要になる可能性が高い（フェーズ 0 で要検証）。

### 5. アラーム導線への接続
Charalarm 既存の CallKit/VoIP 着信フローを維持し、**着信応答後の音声再生処理を会話セッション起動に差し替える**。
`.caf` 再生は当面フォールバックとして残す選択も可。

## フェーズ計画

- **フェーズ 0（調査・確定）**：iOS 18 化の影響範囲、VOICEVOX CORE の Charalarm でのビルド可否、`.vvm` 配布方式を確定。
- **フェーズ 1（TTS PoC）**：`VoicevoxRepository` と xcframework/`.vvm` を Charalarm に取り込み、
  「ずんだもんが一言発話」する最小実装を通す。S3 配信 (`Makefile`) も移植。
- **フェーズ 2（会話ループ）**：`CallViewModel` 系 + `TextChunker` + STT を移植し、
  画面上でターン制会話を成立させる（LLM は backend `/chat` 経由）。
- **フェーズ 3（アラーム接続）**：既存 CallKit 着信フローに会話セッションを接続し、
  「アラーム発火 → 取ると会話」を実機で通す。`.caf` 再生と差し替え。
- **フェーズ 4（LLM/backend）**：Charalarm backend に `/chat`（デフォルト OpenAI・差替可能）を実装し、
  端末からキーを排除。ずんだもんペルソナをサーバ/クライアントで整理。

## 検証方法

- **フェーズ 1**：実機/シミュレータで発話 PoC を起動し、ずんだもん音声が鳴ることを耳で確認。
  合成の WAV が生成されるか、Open JTalk 辞書・`.vvm` が bundle から読めるかをログで確認。
- **フェーズ 2**：マイク入力 → STT テキスト化 → LLM 返答 → 音声再生の 1 ターンが通ることを実機で確認。
  2 秒無音で発話終了、`。！？` 区切りの逐次再生が効くこと。
- **フェーズ 3**：アラームを近い時刻にセット → VoIP Push 着信 → 応答 → 会話開始、を実機で通す。
- **backend**：`cd application && make test`。`/chat` は ZunTalk の `openai_test.go` を参考にテスト追加。
- iOS: SwiftLint (--strict) を維持。

## リスク / 未確認事項

- **iOS 18 引き上げ**：既存 iOS 16/17 ユーザーへの影響。要合意。
- **VOICEVOX CORE の Charalarm ビルド**：xcframework の取り込み・署名・サイズ。フェーズ 0 で潰す。
- **`.vvm`/xcframework の入手**：git 管理外。ZunTalk の S3 (`zuntalk-resources`) か公式 VOICEVOX 配布から取得する運用を Charalarm 側に用意。
- **FoundationModels パスのペルソナ欠落**：ZunTalk では端末内 LLM 経路が汎用プロンプト。今回はサーバ経路主軸なので影響小だが留意。
- **多キャラとの整合**：下記「多キャラ戦略」を参照。

## 多キャラ戦略

会話には「任意テキストを喋れる声（TTS）」が必須で、それを持つのは現状 VOICEVOX キャラのみ。

- **出荷スコープ（近期）**：会話は**ずんだもん専用に振り切る**。他キャラは従来通りのモーニングコール（録音再生）。
- **将来拡張**：四国めたん等の VOICEVOX キャラ、および「独自デザイン＋人格 ＋ 中身は VOICEVOX ボイス」なオリジナルキャラを追加していく。
- **キャラ種別の整理**：
  | 種別 | 例 | 会話 | 追加コスト |
  |---|---|---|---|
  | VOICEVOX キャラ | ずんだもん / 四国めたん | ○ | `0.vvm` に同梱の styleId 追加のみ（激安） |
  | オリジナル（VOICEVOX 声） | 新規キャラ | ○ | 絵・人格は独自、声は VOICEVOX を裏で使う（クレジット表記でOK） |
  | オリジナル（声優録音） | 結衣 / 紅葉 | △ | 任意合成不可。会話させるなら別の声(VOICEVOX)を当てる判断が要る |

- **設計方針**：出荷はずんだもん専用でも、コードは **キャラ = {絵, 人格プロンプト, `voicevoxStyleId`}** で一般化しておく。
  現状 `VoicevoxRepository` の `styleId=3` ベタ書きを**キャラ属性から渡す形**に一般化する（フェーズ2で対応）。
  こうすればめたん／オリジナルの追加が「データ追加」だけで済む。
