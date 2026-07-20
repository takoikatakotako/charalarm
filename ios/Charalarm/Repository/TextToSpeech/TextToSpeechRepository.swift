import Foundation

protocol TextToSpeechRepository {
    func setupSynthesizer() throws
    /// - Parameter styleId: VOICEVOX のスタイルID (ずんだもん ノーマル = 3)。
    ///   会話対応キャラを増やす際はキャラ属性から渡す。
    func synthesize(text: String, styleId: Int) async throws -> Data
    func cleanupSynthesizer()
}
