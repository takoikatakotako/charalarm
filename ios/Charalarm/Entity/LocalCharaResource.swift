import Foundation

struct LocalCharaResource: Codable {
    let charaID: String
    let updatedAt: String
    var expressions: [String: CharaLocalExpression]
    /// 3D の見た目があるキャラの 3D モデル。立ち絵だけのキャラと、これより前に保存したものは nil
    var modelFileURL: URL?
    /// 既定の見た目。これより前に保存したものは nil
    var defaultAppearance: String?
    /// トップでタップしたときのセリフ。これより前に保存したものは nil
    var tapLines: [TapLine]?
    /// 会話できるキャラか（電話で録音ボイスではなく会話画面を出す）。これより前に保存したものは nil
    var supportsConversation: Bool?

    init(chara: Chara) {
        self.charaID = chara.charaID
        self.updatedAt = chara.updatedAt
        self.modelFileURL = chara.modelFileURL
        self.defaultAppearance = chara.appearances.first?.kind.rawValue
        self.tapLines = chara.tapLines
        self.supportsConversation = chara.conversation != nil

        var expressions: [String: CharaLocalExpression] = [:]
        chara.expressions.forEach { touple in
            expressions[touple.key] = CharaLocalExpression(charaExpression: touple.value)
        }
        self.expressions = expressions
    }
}

struct CharaLocalExpression: Codable {
    let imageFileNames: [String]
    let voiceFileNames: [String]

    init(charaExpression: CharaExpression) {
        self.imageFileNames = charaExpression.imageFileURLs.map({ url in
            url.lastPathComponent
        })
        self.voiceFileNames = charaExpression.voiceFileURLs.map({ url in
            url.lastPathComponent
        })
    }
}
