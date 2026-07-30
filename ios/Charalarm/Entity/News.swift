import Foundation

struct News: Decodable, Identifiable {
    var id: String {
        return newsId
    }
    let newsId: String
    let title: String
    let body: String
    let registeredAt: Date

    private enum CodingKeys: String, CodingKey {
        case newsId
        case title
        case body
        case registeredAt
    }
}
