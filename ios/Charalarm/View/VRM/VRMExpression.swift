import Foundation

/// 3D のキャラに出す表情。名前は VRM の標準の表情と同じ（viewer.js にそのまま渡す）
enum VRMExpression: String, CaseIterable {
    case neutral
    case happy
    case angry
    case sad
    case relaxed
    case surprised

    /// 会話で、返事の頭に表情の印を付けてもらう指示（3D で出すときだけ送る）。印は字幕と読み上げの前に外す
    static let prompt = "返答のいちばん最初に、その返答を話すときのあなたの表情を、" +
        allCases.map { "[\($0.rawValue)]" }.joined(separator: " ") +
        " のどれかひとつで付けてください（例：[happy]おはよう！）。会話の内容と気持ちに合う表情を選んでください。" +
        "この印は読み上げる前に外すので、記号を使わない決まりの例外です。印は最初のひとつだけにしてください。"

    /// 返事から表情の印を外して、表情と話す文に分ける。印がなければ表情は nil。
    /// 印が途中や複数にあっても、最初の印を表情にして、ぜんぶ外す
    static func parse(_ response: String) -> (expression: VRMExpression?, text: String) {
        let found = allCases.compactMap { expression in
            response.range(of: "[\(expression.rawValue)]", options: .caseInsensitive).map { (expression, $0.lowerBound) }
        }
        var text = response
        for expression in allCases {
            text = text.replacingOccurrences(of: "[\(expression.rawValue)]", with: "", options: .caseInsensitive)
        }
        return (found.min { $0.1 < $1.1 }?.0, text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
