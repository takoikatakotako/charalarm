import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
    /// assistant が端末の道具を呼んだとき（/chat が返した calls をそのまま入れる）
    var toolCalls: [ChatToolCall]?
    /// role が tool のとき、どの呼び出しの結果か
    var toolCallID: String?

    enum Role: String {
        case system
        case user
        case assistant
        case tool
    }

    init(role: Role, content: String, toolCalls: [ChatToolCall]? = nil, toolCallID: String? = nil) {
        self.role = role.rawValue
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallID = toolCallID
    }
}

/// /chat が頼み返す端末の道具の呼び出し。signature はそのまま送り返す（Gemini の思考の署名）。
struct ChatToolCall: Codable {
    let id: String
    let name: String
    let signature: String?
}
