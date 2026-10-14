import Foundation

/// キャラと会話する言語。設定画面で選び、キャラが話せればその言語で会話する。
enum ConversationLanguage: String, CaseIterable, Identifiable {
    case japanese = "ja"
    case english = "en"

    var id: String { rawValue }

    /// 音声認識に使うロケール
    var locale: Locale {
        switch self {
        case .japanese: return Locale(identifier: "ja-JP")
        case .english: return Locale(identifier: "en-US")
        }
    }

    /// 設定画面に出す名前（言語ごとの自分の名前で出す）
    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        }
    }

    /// 端末の言語。英語なら英語、それ以外は日本語
    static var deviceDefault: ConversationLanguage {
        Locale.preferredLanguages.first?.hasPrefix("en") == true ? .english : .japanese
    }
}
