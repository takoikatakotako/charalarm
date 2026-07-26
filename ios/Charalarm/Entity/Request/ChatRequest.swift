import Foundation

/// backend `/chat` のリクエストボディ。会話履歴（system/user/assistant）を送る。
struct ChatRequest: Encodable {
    let messages: [ChatMessage]
}
