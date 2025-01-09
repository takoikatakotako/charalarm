import Foundation

struct LocalCharaResource: Codable {
    let charaID: String
    let updatedAt: String
    var expressions: [String: CharaLocalExpression]

    init(chara: Chara) {
        self.charaID = chara.charaID
        self.updatedAt = chara.updatedAt

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
