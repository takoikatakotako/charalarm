import Foundation

/// 話題のニュース（エンタメ・ゲーム）。キャラが見出しを紹介する。
/// アプリのお知らせ（News）とは別。
struct TrendNews: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
}
