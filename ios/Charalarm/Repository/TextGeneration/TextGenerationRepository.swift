import Foundation

/// 会話の返答テキストを生成する。将来 OpenAI/Claude/Gemini などを
/// backend `/chat` 経由で差し替えられるよう抽象化しておく。
protocol TextGenerationRepository {
    /// charaID を渡すと、そのキャラの人格プロンプトをサーバ側で付与する。
    /// language は会話の言語。
    /// キャラが端末の道具（カレンダー）を使うときは、使うあいだのひとことを onFiller で先に渡す。
    /// todayEvents で、今日の予定を先に送るかを決める。
    func generateResponse(
        charaID: String,
        language: ConversationLanguage,
        inputs: [ChatMessage],
        todayEvents: TodayEventsPolicy,
        onFiller: @escaping @MainActor (String) -> Void
    ) async throws -> String
}

/// 今日の予定を先に送るか（カレンダーの許可があるときだけ送る）。
enum TodayEventsPolicy {
    /// 送らない
    case none
    /// 設定の「電話の最初に今日の予定を話す」がオンなら送る（電話の最初のひとこと）
    case ifEnabled
    /// 必ず送る（トップの「今日の予定」ボタン）
    case always
}
