import Foundation

/// backend `/tts` のリクエストボディ。声は charaID からサーバが決める。
struct TextToSpeechRequest: Encodable {
    let charaID: String
    let text: String
}
