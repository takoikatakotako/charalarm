import SwiftUI

/// 運営からのお知らせの一覧。話題のニュースと同じ画面（NewsHubView）のタブに入れる
struct NewsList: View {
    let viewState: NewsListViewState

    var body: some View {
        List {
            ForEach(viewState.newsList) { news in
                NewsRow(news: news)
            }
            if viewState.isLoaded && viewState.newsList.isEmpty {
                Text(String(localized: "news-empty"))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NewsList(viewState: NewsListViewState())
}
