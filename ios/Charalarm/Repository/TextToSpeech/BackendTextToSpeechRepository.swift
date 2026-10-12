import Foundation

/// backend `/tts`（Gemini TTS）で合成する。声はサーバがキャラ情報から決める。
struct BackendTextToSpeechRepository: TextToSpeechRepository {
    let charaID: String

    private let apiRepository = APIRepository()
    private let keychainRepository = KeychainRepository()

    func setupSynthesizer() throws {}

    func synthesize(text: String) async throws -> Data {
        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            throw ConversationError.notAuthenticated
        }
        return try await apiRepository.postTextToSpeech(userID: userID, authToken: authToken, charaID: charaID, text: text)
    }

    func cleanupSynthesizer() {}
}
