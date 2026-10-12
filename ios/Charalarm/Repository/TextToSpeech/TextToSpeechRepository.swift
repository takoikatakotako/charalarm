import Foundation

/// キャラの発話を音声（WAV）にする。声はキャラごとに決まるので、生成時に渡す。
protocol TextToSpeechRepository {
    func setupSynthesizer() throws
    func synthesize(text: String) async throws -> Data
    func cleanupSynthesizer()
}
