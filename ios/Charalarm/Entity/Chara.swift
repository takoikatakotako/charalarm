import UIKit

struct Chara: Identifiable, Hashable, Equatable {
    init(charaResponse: CharaResponse) {
        charaID = charaResponse.charaID
        enable = charaResponse.enable
        createdAt = charaResponse.createdAt
        updatedAt = charaResponse.updatedAt
        name = charaResponse.name
        description = charaResponse.description
        profiles = charaResponse.profiles.map { CharaProfile(title: $0.title, name: $0.name, url: $0.url) }
        resources = charaResponse.resources.map { CharaResource(fileURL: $0.fileURL) }
        expressions = charaResponse.expressions.mapValues { CharaExpression(imageFileURLs: $0.imageFileURLs, voiceFileURLs: $0.voiceFileURLs) }
        calls = charaResponse.calls.map { CharaCall(message: $0.message, voiceFileURL: $0.voiceFileURL)}
        appearance = CharaAppearance(response: charaResponse.appearance)
        let appearances = (charaResponse.appearances ?? []).compactMap(CharaAppearance.init(listItem:))
        self.appearances = appearances.isEmpty ? [appearance] : appearances
        tapLines = (charaResponse.tapLines ?? []).map {
            TapLine(language: $0.language, text: $0.text, voiceFileName: $0.voiceFileURL.lastPathComponent, when: $0.when)
        }
        conversation = charaResponse.conversation.flatMap(CharaConversation.init(response:))
    }

    var id: String {
        return charaID
    }

    var thumbnailUrlString: String {
        return "\(Variables.resourceEndpoint)/\(charaID)/thumbnail.png"
    }

    var selfIntroductionUrlString: String {
        return "\(Variables.resourceEndpoint)/\(charaID)/self-introduction.caf"
    }

    static func charaDomainToThmbnailUrlString(charaDomain: String) -> String {
        return "\(String(describing: Variables.resourceEndpoint))/\(charaDomain)/thumbnail.png"
    }

    let charaID: String
    let enable: Bool
    let createdAt: String
    let updatedAt: String
    let name: String
    let description: String
    let profiles: [CharaProfile]
    let resources: [CharaResource]
    let expressions: [String: CharaExpression]
    let calls: [CharaCall]
    /// 既定の見た目（立ち絵か 3D モデルか）。
    let appearance: CharaAppearance
    /// 選べる見た目。先頭が既定。3D と立ち絵の両方があれば、ユーザーが選べる。
    let appearances: [CharaAppearance]
    /// トップでタップしたときのセリフ（ボイスは resources に入っていて、キャラを選んだときにダウンロードする）
    let tapLines: [TapLine]

    /// ユーザーが選んだ見た目。選んでいないか、選んだものがなければ既定。
    func appearance(preferred: CharaAppearanceKind?) -> CharaAppearance {
        appearances.first { $0.kind == preferred } ?? appearances.first ?? appearance
    }

    /// 3D モデルの URL（3D の見た目があれば）。
    var modelFileURL: URL? {
        for appearance in appearances {
            if case .vrm(let modelFileURL) = appearance {
                return modelFileURL
            }
        }
        return nil
    }
    /// 会話の設定。会話に対応しないキャラは nil。
    let conversation: CharaConversation?
}

/// 見た目の種類。ユーザーが選んだものを端末に保存する。
enum CharaAppearanceKind: String {
    case illustration
    case vrm
}

/// キャラの見た目。
enum CharaAppearance: Hashable, Equatable {
    /// 表情ごとの立ち絵（expressions の画像）。
    case illustration
    /// 3D モデル（VRM）。
    case vrm(modelFileURL: URL)

    var kind: CharaAppearanceKind {
        switch self {
        case .illustration: return .illustration
        case .vrm: return .vrm
        }
    }

    /// 知らないタイプや、VRM なのにモデルがないときは立ち絵として扱う。
    init(response: CharaAppearanceResponse?) {
        if response?.type == "vrm", let modelFileURL = response?.modelFileURL {
            self = .vrm(modelFileURL: modelFileURL)
        } else {
            self = .illustration
        }
    }

    /// 選べる見た目の一覧の1つ。知らないタイプは選べないので nil。
    init?(listItem response: CharaAppearanceResponse) {
        switch response.type {
        case "vrm":
            guard let modelFileURL = response.modelFileURL else { return nil }
            self = .vrm(modelFileURL: modelFileURL)
        case "illustration":
            self = .illustration
        default:
            return nil
        }
    }
}

/// キャラとの通話（会話）の設定。
struct CharaConversation: Hashable, Equatable {
    enum VoiceProvider: String {
        /// 端末内の VOICEVOX で合成する。
        case voicevox
        /// サーバの /tts（Gemini TTS）で合成する。
        case gemini
    }

    let voiceProvider: VoiceProvider
    let voicevoxStyleID: Int
    /// 会話できる言語。先頭が第一言語。
    let languages: [ConversationLanguage]
    /// 通話の場面の指示。/chat に system として送る。
    let openingPrompt: String
    let endingPrompt: String
    let noInputEndingPrompt: String

    /// ユーザーが選んだ言語で話せればその言語、話せなければキャラの第一言語。
    func language(preferred: ConversationLanguage) -> ConversationLanguage {
        languages.contains(preferred) ? preferred : (languages.first ?? .japanese)
    }

    /// 知らない声の出し方なら nil（古いアプリでは会話しない）。
    init?(response: CharaConversationResponse) {
        guard let voiceProvider = VoiceProvider(rawValue: response.voiceProvider) else {
            return nil
        }
        self.voiceProvider = voiceProvider
        voicevoxStyleID = response.voicevoxStyleID
        let languages = (response.languages ?? []).compactMap(ConversationLanguage.init(rawValue:))
        self.languages = languages.isEmpty ? [.japanese] : languages
        openingPrompt = response.openingPrompt
        endingPrompt = response.endingPrompt
        noInputEndingPrompt = response.noInputEndingPrompt
    }
}

struct CharaProfile: Hashable, Equatable {
    let title: String
    let name: String
    let url: URL
}

struct CharaResource: Hashable, Equatable {
    let fileURL: URL
}

struct CharaExpression: Hashable, Equatable {
    let imageFileURLs: [URL]
    let voiceFileURLs: [URL]
}

struct CharaCall: Hashable, Equatable {
    let message: String
    let voiceFileURL: URL
}
