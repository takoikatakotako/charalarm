import Foundation

/// トップでキャラをタップしたときのセリフ。ボイスは流すときにダウンロードして、端末に取っておく（TapLineRepository）。
struct TapLine: Codable, Hashable {
    /// セリフの言語（ConversationLanguage の rawValue）。古いデータは nil（日本語）
    let language: String?
    let text: String
    /// ボイスのファイル名（端末に取っておくときの名前）
    let voiceFileName: String
    /// ボイスの URL。キャラを選んだときにダウンロードしていた古いデータは nil
    var voiceFileURL: URL?
    let when: TapLineWhen

    /// 条件がなければ、いつでも流せるセリフ
    var isAnytime: Bool {
        when.dates.isEmpty && when.hours.isEmpty && when.weekdays.isEmpty
    }
}

/// セリフを流す条件。空の項目は条件にしない。
struct TapLineWhen: Codable, Hashable {
    /// 日付（"MM-DD"）
    let dates: [String]
    /// 時間帯 [開始, 終了)。開始 > 終了なら日をまたぐ
    let hours: [Int]
    /// 曜日（0 = 日曜）
    let weekdays: [Int]

    func matches(_ date: Date, calendar: Calendar = .current) -> Bool {
        let components = calendar.dateComponents([.month, .day, .hour, .weekday], from: date)
        if !dates.isEmpty {
            let today = String(format: "%02d-%02d", components.month ?? 0, components.day ?? 0)
            guard dates.contains(today) else { return false }
        }
        if hours.count == 2, let hour = components.hour {
            let (start, end) = (hours[0], hours[1])
            let inRange = start < end ? (start <= hour && hour < end) : (hour >= start || hour < end)
            guard inRange else { return false }
        }
        if !weekdays.isEmpty, let weekday = components.weekday {
            // Calendar の weekday は 1 = 日曜
            guard weekdays.contains(weekday - 1) else { return false }
        }
        return true
    }
}

/// 今の日時に合うセリフを選ぶ。クリスマスなど条件つきのセリフに当たれば優先し、最近流したものは避ける。
enum TapLineSelector {
    /// 会話の言語のセリフ。その言語のセリフがなければ日本語のセリフ（キャラの言語）
    static func lines(_ lines: [TapLine], in language: ConversationLanguage) -> [TapLine] {
        let matched = lines.filter { ($0.language ?? ConversationLanguage.japanese.rawValue) == language.rawValue }
        if !matched.isEmpty {
            return matched
        }
        return lines.filter { ($0.language ?? ConversationLanguage.japanese.rawValue) == ConversationLanguage.japanese.rawValue }
    }

    /// 条件つきのセリフに当たったとき、それを流す割合
    static let conditionalRate = 0.7

    static func select(
        from lines: [TapLine],
        now: Date = Date(),
        recent: [TapLine] = [],
        random: () -> Double = { Double.random(in: 0..<1) }
    ) -> TapLine? {
        let fresh = lines.filter { !recent.contains($0) }
        let candidates = fresh.isEmpty ? lines : fresh
        let conditional = candidates.filter { !$0.isAnytime && $0.when.matches(now) }
        let anytime = candidates.filter { $0.isAnytime }

        if !conditional.isEmpty && (anytime.isEmpty || random() < conditionalRate) {
            return conditional.randomElement()
        }
        return anytime.randomElement()
    }
}
