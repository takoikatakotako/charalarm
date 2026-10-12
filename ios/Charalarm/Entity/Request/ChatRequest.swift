import Foundation

/// backend `/chat` のリクエストボディ。charaID と会話履歴を送る。
/// キャラの人格プロンプトはサーバ側で付与される。
struct ChatRequest: Encodable {
    let charaID: String
    let messages: [ChatMessage]
    let context: ChatContext
}

/// 端末のその場の情報。サーバが「今日は何曜日の何時か」をキャラに伝えるのに使う。
struct ChatContext: Encodable {
    /// 端末の現在時刻（RFC 3339）。
    let now: String
    let timeZone: String

    static func current(date: Date = Date(), timeZone: TimeZone = .current) -> ChatContext {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timeZone
        return ChatContext(now: formatter.string(from: date), timeZone: timeZone.identifier)
    }
}
