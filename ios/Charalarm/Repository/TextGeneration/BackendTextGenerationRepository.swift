import Foundation

/// backend `/chat` を叩いて会話応答を生成する本番実装。
/// LLM のプロバイダと認証はサーバ側が持ち、差し替えもサーバ側で完結する
/// （クライアントは会話履歴とその場の情報を送るだけ）。
struct BackendTextGenerationRepository: TextGenerationRepository {

    private let apiRepository = APIRepository()
    private let keychainRepository = KeychainRepository()

    func generateResponse(charaID: String, inputs: [ChatMessage]) async throws -> String {
        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            throw ConversationError.notAuthenticated
        }
        return try await apiRepository.postChat(userID: userID, authToken: authToken, charaID: charaID, messages: inputs, context: .current())
    }
}
