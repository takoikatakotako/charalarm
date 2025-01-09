import Foundation

struct News: Decodable, Identifiable {
    var id: Int {
        return newsId
    }
    let newsId: Int
    let siteName: String
    let url: String
    let title: String
    let description: String
    let registeredAt: Date

    private enum CodingKeys: String, CodingKey {
        case newsId
        case siteName
        case url
        case title
        case description
        case registeredAt
    }
}
