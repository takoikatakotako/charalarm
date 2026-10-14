import Foundation

struct CharaResponse: Response {
    let charaID: String
    let enable: Bool
    let createdAt: String
    let updatedAt: String
    let name: String
    let description: String
    let profiles: [CharaProfileResponse]
    let resources: [CharaResourceResponse]
    let expressions: [String: CharaExpressionResponse]
    let calls: [CharaCallResponse]
    /// 見た目。古いサーバは返さないので省略できる。
    let appearance: CharaAppearanceResponse?
    /// 選べる見た目。先頭が既定。古いサーバは返さないので省略できる。
    let appearances: [CharaAppearanceResponse]?
    /// 会話に対応するキャラだけが持つ。
    let conversation: CharaConversationResponse?
}

/// 見た目。type が "vrm" のときは modelFileURL に 3D モデルがある。
struct CharaAppearanceResponse: Response {
    let type: String
    let modelFileURL: URL?
}

/// 会話の設定。キャラの人格プロンプトと Gemini の声はサーバだけが持つ。
struct CharaConversationResponse: Response {
    let voiceProvider: String
    let voicevoxStyleID: Int
    /// 会話できる言語。古いサーバは返さないので省略できる（日本語だけ）。
    let languages: [String]?
    let openingPrompt: String
    let endingPrompt: String
    let noInputEndingPrompt: String
}

struct CharaProfileResponse: Response {
    let title: String
    let name: String
    let url: URL
}

struct CharaResourceResponse: Response {
    let fileURL: URL
}

struct CharaExpressionResponse: Response {
    let imageFileURLs: [URL]
    let voiceFileURLs: [URL]
}

struct CharaCallResponse: Response {
    let message: String
    let voiceFileName: String
    let voiceFileURL: URL
}
