import SwiftUI

/// 話題のニュースの一覧。「読んでもらう」でキャラが見出しを紹介する。
struct TrendNewsView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: TrendNewsRepository
    /// 「読んでもらう」を押したときに、表示中のニュースを渡す
    let onRead: ([TrendNews]) -> Void

    @State private var newsList: [TrendNews] = []
    @State private var failed = false

    var body: some View {
        NavigationStack {
            List {
                if repository.isSample {
                    Text(String(localized: "trend-news-sample-notice"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ForEach(newsList) { news in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(news.title)
                            .font(.headline)
                        Text(news.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                if failed {
                    Text(String(localized: "trend-news-failed"))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(String(localized: "trend-news-title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(R.image.commonIconClose.name)
                            .renderingMode(.template)
                            .foregroundStyle(Color(R.color.charalarmDefaultGray.name))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "trend-news-read")) {
                        let news = newsList
                        dismiss()
                        onRead(news)
                    }
                    .disabled(newsList.isEmpty)
                }
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
    TrendNewsView(repository: DummyTrendNewsRepository()) { _ in }
}
