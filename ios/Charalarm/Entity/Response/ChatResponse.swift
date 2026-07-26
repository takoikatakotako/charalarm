import Foundation

/// backend `/chat` のレスポンス。message はずんだもんの応答テキスト。
struct ChatResponse: Response {
    let message: String
}
