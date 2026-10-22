import SwiftUI

@MainActor @Observable final class NewsListViewState {
    var newsList: [News] = []
    var isLoaded = false
    var showingAlert = false
    var alertMessage = ""
    private let newsRepository = NewsRepository()

    func fetchNews() async {
        do {
            newsList = try await newsRepository.fetchNews()
            isLoaded = true
        } catch {
            alertMessage = String(localized: "news-failed-to-get-the-news")
            showingAlert = true
        }
    }
}
