import SwiftUI

/// 話題のニュースの一覧。ニュースを押すと、キャラがそのニュースを紹介する。
/// お知らせと同じ画面（NewsHubView）のタブに入れる。
struct TrendNewsList: View {
    let repository: TrendNewsRepository
    /// 押したニュースを渡す（キャラが紹介する）
    let onRead: ([TrendNews]) -> Void

    @State private var newsList: [TrendNews] = []
    @State private var failed = false

    var body: some View {
        List {
            if repository.isSample {
                Text(String(localized: "trend-news-sample-notice"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if !newsList.isEmpty {
                Button {
                    onRead(newsList)
                } label: {
                    Label(String(localized: "trend-news-read-all"), systemImage: "play.circle.fill")
                        .font(.headline)
                }
            }
            ForEach(newsList) { news in
                Button {
                    onRead([news])
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(news.title)
                                .font(.headline)
                            Text(news.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "play.circle")
                            .font(.title2)
                            .foregroundStyle(Color.brand)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(String(localized: "trend-news-read"))
            }
            if failed {
                Text(String(localized: "trend-news-failed"))
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            do {
                newsList = try await repository.fetchTrendNews()
            } catch {
                CharalarmLogger.error("話題のニュースを取れませんでした", error: error)
                failed = true
            }
        }
    }
}

#Preview {
    TrendNewsList(repository: DummyTrendNewsRepository()) { _ in }
}
