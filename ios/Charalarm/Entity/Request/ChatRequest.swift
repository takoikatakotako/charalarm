import Foundation

/// backend `/chat` のリクエストボディ。charaID と会話履歴を送る。
/// キャラの人格プロンプトはサーバ側で付与される。
struct ChatRequest: Encodable {
    let charaID: String
    /// 会話の言語（"ja" / "en"）。キャラが話せなければサーバがキャラの言語にする。
    let language: String
    /// 端末で使える道具（例: calendar.read）。許可がないものは入れない
    let capabilities: [String]
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
