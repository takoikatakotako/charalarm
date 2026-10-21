import Foundation

/// 音声合成のために長文を文単位のチャンクに分割する。
enum TextChunker {
    /// 1チャンクの最大文字数。サーバ（/tts）の上限 200 文字より少し短くしておく
    static let maxChunkLength = 180

    /// 全角の「。」「！」「？」と改行は、そこで文が終わる
    private static let sentenceEnds: Set<Character> = ["。", "！", "？", "\n"]
    /// 半角の「.」「!」「?」は、後ろが空白か文末のときだけ文が終わる（「3.14」や「e.g.」の途中で切らない）
    private static let asciiSentenceEnds: Set<Character> = [".", "!", "?"]
    /// 長すぎる文を切ってよいところ
    private static let pauses: Set<Character> = ["、", "，", ",", "；", ";", "：", ":", " ", "　"]

    /// 文単位に分割する。文が長すぎるときは、読点や空白で maxChunkLength 文字以内に切る。
    static func split(_ text: String) -> [String] {
        splitSentences(text)
            .flatMap(splitLongSentence)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private static func splitSentences(_ text: String) -> [String] {
        let characters = Array(text)
        var sentences: [String] = []
        var current = ""

        for (index, char) in characters.enumerated() {
            current.append(char)
            let isEnd: Bool
            if sentenceEnds.contains(char) {
                isEnd = true
            } else if asciiSentenceEnds.contains(char) {
                let next = index + 1 < characters.count ? characters[index + 1] : nil
                isEnd = next == nil || next?.isWhitespace == true
            } else {
                isEnd = false
            }
            if isEnd {
                sentences.append(current)
                current = ""
            }
        }
        if !current.isEmpty {
            sentences.append(current)
        }
        return sentences
    }

    /// maxChunkLength 文字を超える文を、できるだけ後ろの読点や空白で切る。切れるところがなければ文字数で切る
    private static func splitLongSentence(_ sentence: String) -> [String] {
        var chunks: [String] = []
        var rest = Substring(sentence)

        while rest.count > maxChunkLength {
            let head = rest.prefix(maxChunkLength)
            let cutIndex: Substring.Index
            if let pauseIndex = head.lastIndex(where: { pauses.contains($0) }), pauseIndex > head.startIndex {
                cutIndex = rest.index(after: pauseIndex)
            } else {
                cutIndex = head.endIndex
            }
            chunks.append(String(rest[..<cutIndex]))
            rest = rest[cutIndex...]
        }
        if !rest.isEmpty {
            chunks.append(String(rest))
        }
        return chunks
    }
}
