import Foundation

/// backend `/tts` のリクエストボディ。自分のキャラは選んだ voiceID を送り、通常のキャラはサーバが声を決める。
struct TextToSpeechRequest: Encodable {
    let charaID: String
    let text: String
    var voiceID: String?
}
