import Foundation

// MARK: - Trend News

extension ConversationViewState {

    /// 電話の最初に話題のニュースに触れてもらう指示。設定でオフ・ニュースが取れないときは nil（ニュースには触れない）
    func callNewsPrompt() async -> String? {
        guard callSettings.news else { return nil }
        do {
            let news = try await ResourceTrendNewsRepository().fetchTrendNews()
            guard !news.isEmpty else { return nil }
            return ConversationTopic.callNewsPrompt(Array(news.prefix(3)))
        } catch {
            CharalarmLogger.error("電話で触れる話題のニュースを取れませんでした", error: error)
            return nil
        }
    }
}
