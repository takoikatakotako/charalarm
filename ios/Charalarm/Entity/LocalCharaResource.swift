import Foundation

struct LocalCharaResource: Codable {
    let charaID: String
    let updatedAt: String
    var expressions: [String: CharaLocalExpression]
    /// 見た目が VRM のキャラの 3D モデル。立ち絵のキャラと、これより前に保存したものは nil
    var modelFileURL: URL?

    init(chara: Chara) {
        self.charaID = chara.charaID
        self.updatedAt = chara.updatedAt
        if case .vrm(let modelFileURL) = chara.appearance {
            self.modelFileURL = modelFileURL
        }

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
