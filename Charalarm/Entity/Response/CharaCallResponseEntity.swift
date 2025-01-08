import Foundation

struct CharaCallResponseEntity: Identifiable, Response, Hashable {
    var id: Int {
        return charaCallId
    }

    let charaCallId: Int
    let charaFileName: String
    let charaFileMessage: String
    let charaFilePath: String
}
