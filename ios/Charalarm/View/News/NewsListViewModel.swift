import SwiftUI

@Observable class NewsListViewModel {
    var newsList: [News] = []
    var showingAlert = false
    var alertMessage = ""
    // let newsRepository: NewsRepository = NewsRepository()

    func fetchNews() {
        Task { @MainActor in
//            do {
//                // let news = try await newsRepository.fetchNews()
//                // self.newsList = news
//            } catch {
//                self.alertMessage = String(localized: "news-failed-to-get-the-news")
//                self.showingAlert = true
//            }
        }
    }
}
