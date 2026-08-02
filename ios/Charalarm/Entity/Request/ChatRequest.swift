import Foundation

/// backend `/chat` のリクエストボディ。charaID と会話履歴を送る。
/// キャラの人格プロンプトはサーバ側で付与される。
struct ChatRequest: Encodable {
    let charaID: String
    let messages: [ChatMessage]
}
