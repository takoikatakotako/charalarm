import Foundation

/// backend `/tts` のリクエストボディ。声はサーバのキャラ設定で決める。
struct TextToSpeechRequest: Encodable {
    let charaID: String
    let text: String
}
