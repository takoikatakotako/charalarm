import Foundation

enum ConversationStatus {
    case idle                       // 初期化前
    case initializingVoiceVox       // VOICEVOX セットアップ中
    case requestingPermission       // 音声認識の許可リクエスト中
    case generatingScript           // 返答生成中
    case synthesizingVoice          // 音声合成中
    case playingVoice               // 音声再生中
    case recognizingSpeech          // 音声認識中
    case ended                      // 会話終了
}
