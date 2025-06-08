import SwiftUI

class NewsListViewModel: ObservableObject {
    @Published var newsList: [News] = []
    @Published var showingAlert = false
    @Published var alertMessage = ""
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
