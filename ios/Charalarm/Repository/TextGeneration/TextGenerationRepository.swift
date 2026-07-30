import Foundation

/// 会話の返答テキストを生成する。将来 OpenAI/Claude/Gemini などを
/// backend `/chat` 経由で差し替えられるよう抽象化しておく。
protocol TextGenerationRepository {
    func generateResponse(inputs: [ChatMessage]) async throws -> String
}
