import Foundation

/// 会話の返答テキストを生成する。将来 OpenAI/Claude/Gemini などを
/// backend `/chat` 経由で差し替えられるよう抽象化しておく。
protocol TextGenerationRepository {
    /// charaID を渡すと、そのキャラの人格プロンプトをサーバ側で付与する。
    /// language は会話の言語。
    /// キャラが端末の道具（カレンダー）を使うときは、使うあいだのひとことを onFiller で先に渡す。
    /// includeTodayEvents なら（電話の最初のひとこと）、設定でオンにしていれば今日の予定を先に送る。
    func generateResponse(
        charaID: String,
        language: ConversationLanguage,
        inputs: [ChatMessage],
        includeTodayEvents: Bool,
        onFiller: @escaping @MainActor (String) -> Void
    ) async throws -> String
}
