import Foundation

/// 話題のニュースを取る。
protocol TrendNewsRepository {
    /// ダミー（サンプル）のニュースなら true。画面に「サンプル」と出す
    var isSample: Bool { get }
    func fetchTrendNews() async throws -> [TrendNews]
}

/// 画面と会話の流れを試すためのダミーのニュース。
/// 本物は、サーバのバッチが X の話題（Grok）から作ったものを API で返す予定（規約と中身の確かめ方を決めてから）。
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
