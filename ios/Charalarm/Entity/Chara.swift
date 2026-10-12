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
    /// 会話の設定。会話に対応しないキャラは nil。
    let conversation: CharaConversation?
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
    /// 通話の場面の指示。/chat に system として送る。
    let openingPrompt: String
    let endingPrompt: String
    let noInputEndingPrompt: String

    /// 知らない声の出し方なら nil（古いアプリでは会話しない）。
    init?(response: CharaConversationResponse) {
        guard let voiceProvider = VoiceProvider(rawValue: response.voiceProvider) else {
            return nil
        }
        self.voiceProvider = voiceProvider
        voicevoxStyleID = response.voicevoxStyleID
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
