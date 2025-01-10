import Foundation

struct CharaResponse: Response {
    let charaID: String
    let enable: Bool
    let createdAt: String
    let updatedAt: String
    let name: String
    let description: String
    let profiles: [CharaProfileResponse]
    let resources: [CharaResourceResponse]
    let expressions: [String: CharaExpressionResponse]
    let calls: [CharaCallResponse]
}

struct CharaProfileResponse: Response {
    let title: String
    let name: String
    let url: URL
}

struct CharaResourceResponse: Response {
    let fileURL: URL
}

struct CharaExpressionResponse: Response {
    let imageFileURLs: [URL]
    let voiceFileURLs: [URL]
}

struct CharaCallResponse: Response {
    let message: String
    let voiceFileName: String
    let voiceFileURL: URL
}
