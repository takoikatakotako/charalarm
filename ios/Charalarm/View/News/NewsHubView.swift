import SwiftUI

/// 話題のニュースとお知らせを1つにまとめた画面。上のタブか左右のスワイプで切り替える
struct NewsHubView: View {
    enum Tab: Hashable {
        case trend
        case news
    }

    let trendNewsRepository: TrendNewsRepository
    /// 最初に開くタブ（読んでいないお知らせがあればお知らせ）
    let initialTab: Tab
    /// 話題のニュースを押したとき（キャラが紹介する）
    let onReadTrendNews: ([TrendNews]) -> Void

    init(trendNewsRepository: TrendNewsRepository, initialTab: Tab, onReadTrendNews: @escaping ([TrendNews]) -> Void) {
        self.trendNewsRepository = trendNewsRepository
        self.initialTab = initialTab
        self.onReadTrendNews = onReadTrendNews
        _tab = State(initialValue: initialTab)
    }

    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab
    @State private var newsViewState = NewsListViewState()

    var body: some View {
        NavigationStack {
            ZStack {
                switch tab {
                case .trend:
                    TrendNewsList(repository: trendNewsRepository) { news in
                        dismiss()
                        onReadTrendNews(news)
                    }
                    .transition(.move(edge: .leading))
                case .news:
                    NewsList(viewState: newsViewState)
                        .transition(.move(edge: .trailing))
                }
            }
            .background(Color(.systemGroupedBackground))
            // 左右のスワイプでもタブを切り替える（縦のスクロールとは別に受け取る）
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                        withAnimation {
                            if value.translation.width < -60 {
                                tab = .news
                            } else if value.translation.width > 60 {
                                tab = .trend
                            }
                        }
                    }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseBarButton {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Picker(String(localized: "top-news"), selection: $tab.animation()) {
                        Text(String(localized: "top-trend-news")).tag(Tab.trend)
                        Text(String(localized: "top-news")).tag(Tab.news)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
        }
        .task {
            await newsViewState.fetchNews()
            markNewsAsSeenIfShown()
        }
        .onChange(of: tab) {
            markNewsAsSeenIfShown()
        }
        .alert("", isPresented: $newsViewState.showingAlert) {
            Button(String(localized: "common-close")) {}
        } message: {
            Text(newsViewState.alertMessage)
        }
    }

    /// お知らせのタブを見たら、いちばん新しいお知らせまで読んだことにする（ベルの点を消す）
    private func markNewsAsSeenIfShown() {
        guard tab == .news, let latest = newsViewState.newsList.map(\.registeredAt).max() else { return }
        UserDefaultsRepository().setLastSeenNewsAt(latest)
    }
}

#Preview {
    NewsHubView(trendNewsRepository: DummyTrendNewsRepository(), initialTab: .trend) { _ in }
}
