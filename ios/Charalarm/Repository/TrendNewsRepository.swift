import Foundation

/// 話題のニュースを取る。
protocol TrendNewsRepository {
    /// ダミー（サンプル）のニュースなら true。画面に「サンプル」と出す
    var isSample: Bool { get }
    func fetchTrendNews() async throws -> [TrendNews]
}

enum TrendNewsError: Error {
    /// 配っている一覧を取れなかった
    case unavailable
}

/// batch が 1 日に数回作って CloudFront で配るニュース（resource の trend-news/ja.json と en.json）。
/// X のニュースから、子ども（9+）が朝に聞いてよいものを Gemini で選び、日本語版と英語版を作ってある。
/// 会話の言語が日本語なら日本語版、それ以外は英語版を読む（キャラが会話の言語で紹介し直す）。作ってから 1 日以上たったものは使わない
struct ResourceTrendNewsRepository: TrendNewsRepository {
    let isSample = false
    /// これより古い一覧は使わない（batch が止まっていても、古いニュースを読み上げない）
    static let maxAge: TimeInterval = 24 * 60 * 60

    private struct Feed: Decodable {
        let generatedAt: Date
        let items: [TrendNews]
    }

    func fetchTrendNews() async throws -> [TrendNews] {
        let file = UserDefaultsRepository().getConversationLanguage() == .japanese ? "ja" : "en"
        guard let url = URL(string: Variables.resourceEndpoint + "/trend-news/\(file).json") else {
            throw TrendNewsError.unavailable
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TrendNewsError.unavailable
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let feed = try decoder.decode(Feed.self, from: data)
        guard Date().timeIntervalSince(feed.generatedAt) < Self.maxAge else {
            return []
        }
        return feed.items
    }
}

/// 画面と会話の流れを試すためのダミーのニュース（プレビュー用）。
struct DummyTrendNewsRepository: TrendNewsRepository {
    let isSample = true

    func fetchTrendNews() async throws -> [TrendNews] {
        [
            TrendNews(
                id: "sample-zelda",
                title: "『ゼルダの伝説』シリーズの新作が発売予定",
                summary: "任天堂から『ゼルダの伝説』シリーズの新作が近く発売される予定です。（サンプルのニュースです）"
            ),
            TrendNews(
                id: "sample-mario",
                title: "マリオの新作アクションゲームが登場予定",
                summary: "任天堂からマリオの新しいアクションゲームが発売される予定です。（サンプルのニュースです）"
            ),
            TrendNews(
                id: "sample-direct",
                title: "ニンテンドーダイレクトで新作がまとめて紹介",
                summary: "ニンテンドーダイレクトで、これから発売されるゲームがまとめて紹介されました。（サンプルのニュースです）"
            )
        ]
    }
}
