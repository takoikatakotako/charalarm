import Foundation

/// 電話（AI 会話）の設定。電話の長さと、電話の最初に今日の予定・天気・話題のニュースに触れるか。
/// アラームごとに持ち、アラームと一緒にサーバ（alarm-table）に保存して、VoIP の中身で届く。
/// アラームの無い電話（ホームの電話ボタン）と、設定の無い古いアラームは、アプリ共通の設定（appDefault）を使う。
/// センシティブな値（予定の中身・天気の地域）は持たず、話すかどうかだけを持つ（地域は端末の設定を使う）
struct CallSettings: Codable, Hashable {
    var timeLimit: CallTimeLimit
    var schedule: Bool
    var weather: Bool
    var news: Bool

    /// アプリ共通の設定（設定画面の値）
    static var appDefault: CallSettings {
        let repository = UserDefaultsRepository()
        return CallSettings(
            timeLimit: repository.getCallTimeLimit(),
            schedule: repository.getMentionScheduleOnCall(),
            weather: repository.getWeatherRegion() != nil,
            news: repository.getMentionNewsOnCall()
        )
    }

    init(timeLimit: CallTimeLimit, schedule: Bool, weather: Bool, news: Bool) {
        self.timeLimit = timeLimit
        self.schedule = schedule
        self.weather = weather
        self.news = news
    }

    /// VoIP の中身（値はすべて文字列）から読む。アラームに設定が無ければ nil
    init?(payload: [String: String]) {
        guard let seconds = payload["callTimeLimit"].flatMap(Int.init) else { return nil }
        self.init(
            timeLimit: CallTimeLimit(rawValue: seconds) ?? .default,
            schedule: payload["callSchedule"] == "true",
            weather: payload["callWeather"] == "true",
            news: payload["callNews"] == "true"
        )
    }

    // MARK: - Codable（サーバの alarm の call と同じ形）

    private enum CodingKeys: String, CodingKey {
        case timeLimit, schedule, weather, news
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // 知らない長さが来ても、アラームの一覧を読めなくしない
        let seconds = try container.decode(Int.self, forKey: .timeLimit)
        timeLimit = CallTimeLimit(rawValue: seconds) ?? .default
        schedule = try container.decode(Bool.self, forKey: .schedule)
        weather = try container.decode(Bool.self, forKey: .weather)
        news = try container.decode(Bool.self, forKey: .news)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timeLimit.rawValue, forKey: .timeLimit)
        try container.encode(schedule, forKey: .schedule)
        try container.encode(weather, forKey: .weather)
        try container.encode(news, forKey: .news)
    }
}
