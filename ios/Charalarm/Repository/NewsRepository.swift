import Foundation

struct NewsRepository {
    private let apiRepository = APIRepository()

    func fetchNews() async throws -> [News] {
        try await apiRepository.getNewsList()
    }
}
