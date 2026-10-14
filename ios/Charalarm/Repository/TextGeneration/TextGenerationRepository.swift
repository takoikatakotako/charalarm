import Foundation

/// 会話の返答テキストを生成する。将来 OpenAI/Claude/Gemini などを
/// backend `/chat` 経由で差し替えられるよう抽象化しておく。
protocol TextGenerationRepository {
    /// charaID を渡すと、そのキャラの人格プロンプトをサーバ側で付与する。
    /// language は会話の言語。
    func generateResponse(charaID: String, language: ConversationLanguage, inputs: [ChatMessage]) async throws -> String
}
