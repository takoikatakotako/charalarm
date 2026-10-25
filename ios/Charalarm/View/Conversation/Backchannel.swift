import Foundation

/// 相づち（「うん」「はい」など）。キャラが話している最中に相づちを打っても、話を止めたり返事を始めたりしない
enum Backchannel {
    /// 相づちとして聞き流す言葉。長いものから順に照らし合わせる
    private static let words: [String] = [
        "なるほど", "そうなんだ", "そうなんですね", "そうだね", "そうですね", "そっか", "そうか", "そうそう", "そう",
        "うんうん", "うん", "はいはい", "はい", "へえ", "へー", "ふーん", "ふむ", "ほう", "ああ", "あー", "ええ", "えー", "おお",
        "uh-huh", "yeah", "yes", "yep", "okay", "ok", "right", "sure", "mm-hmm", "mhm", "hmm", "oh", "i see", "wow"
    ].sorted { $0.count > $1.count }

    /// 区切りとして無視する文字
    private static let ignored = CharacterSet.whitespacesAndNewlines
        .union(.punctuationCharacters)
        .union(.symbols)
        .union(CharacterSet(charactersIn: "ー〜～"))

    /// 聞き取れた言葉が相づちだけか（空も相づちとみなす）
    static func isOnly(_ text: String) -> Bool {
        var rest = Substring(text.lowercased())
        while true {
            rest = rest.drop { $0.unicodeScalars.allSatisfy(ignored.contains) }
            if rest.isEmpty { return true }
            guard let word = words.first(where: { rest.hasPrefix($0) }) else { return false }
            rest = rest.dropFirst(word.count)
        }
    }
}
