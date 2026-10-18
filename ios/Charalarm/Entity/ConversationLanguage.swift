import Foundation

/// キャラと会話する言語。設定画面で選び、キャラが話せればその言語で会話する。
/// rawValue はサーバと同じ BCP 47 の言語コード。
enum ConversationLanguage: String, CaseIterable, Identifiable {
    case japanese = "ja"
    case english = "en"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"

    var id: String { rawValue }

    /// 音声認識に使うロケール
    var locale: Locale {
        switch self {
        case .japanese: return Locale(identifier: "ja-JP")
        case .english: return Locale(identifier: "en-US")
        case .chineseSimplified: return Locale(identifier: "zh-CN")
        case .chineseTraditional: return Locale(identifier: "zh-TW")
        case .korean: return Locale(identifier: "ko-KR")
        case .spanish: return Locale(identifier: "es-ES")
        case .french: return Locale(identifier: "fr-FR")
        case .german: return Locale(identifier: "de-DE")
        }
    }

    /// 設定画面に出す名前（言語ごとの自分の名前で出す）
    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        case .korean: return "한국어"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        }
    }

    /// 端末の言語。対応していない言語なら英語
    static var deviceDefault: ConversationLanguage {
        guard let preferred = Locale.preferredLanguages.first else {
            return .japanese
        }
        return from(languageIdentifier: preferred)
    }

    /// 端末の言語の指定（例: "zh-Hant-TW", "de-DE"）から選ぶ
    static func from(languageIdentifier identifier: String) -> ConversationLanguage {
        let language = Locale.Language(identifier: identifier)
        switch language.languageCode?.identifier {
        case "ja": return .japanese
        case "en": return .english
        case "ko": return .korean
        case "es": return .spanish
        case "fr": return .french
        case "de": return .german
        case "zh":
            // 繁体字（台湾・香港）か簡体字か
            if language.script?.identifier == "Hant" || ["TW", "HK", "MO"].contains(language.region?.identifier ?? "") {
                return .chineseTraditional
            }
            return .chineseSimplified
        default:
            return .english
        }
    }
}
