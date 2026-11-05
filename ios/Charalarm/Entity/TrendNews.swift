import Foundation

/// 話題のニュース（ゲーム・アニメ・マンガなど）。キャラが見出しを紹介する。
/// batch が X のニュースから、子ども（9+）が朝に聞いてよいものを選んで配る。アプリのお知らせ（News）とは別。
struct TrendNews: Identifiable, Equatable, Decodable {
    let id: String
    let title: String
    /// 1〜2 文の短い紹介。キャラが読み上げるときに使う
    var hook: String = ""
    /// 長めの要約。一覧で見せる
    let summary: String
    /// X のニュースのページ（もとの投稿を辿れる）。古い一覧には無い
    var url: URL?

    /// キャラに渡す紹介文。短い紹介がなければ要約
    var introduction: String {
        hook.isEmpty ? summary : hook
    }
}
