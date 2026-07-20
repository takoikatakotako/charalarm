import Foundation

protocol TextToSpeechRepository {
    func setupSynthesizer() throws
    func synthesize(text: String) async throws -> Data
    func cleanupSynthesizer()
}
