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
    }

    var id: String {
        return charaID
    }

    var thumbnailUrlString: String {
        return "\(EnvironmentVariableConfig.resourceEndpoint)/\(charaID)/thumbnail.png"
    }

    var selfIntroductionUrlString: String {
        return "\(EnvironmentVariableConfig.resourceEndpoint)/\(charaID)/self-introduction.caf"
    }

    static func charaDomainToThmbnailUrlString(charaDomain: String) -> String {
        return "\(String(describing: EnvironmentVariableConfig.resourceEndpoint))/\(charaDomain)/thumbnail.png"
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
