import Foundation

/// backend `/chat` のレスポンス。
/// type が toolCall なら、message は道具を使うあいだのひとことで、calls を端末で実行して呼び直す。
struct ChatResponse: Response {
    let type: String?
    let message: String
    let calls: [ChatToolCall]?
}
