import SwiftUI

struct NewsRow: View {
    let news: News

    private var registerdAtString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.string(from: news.registeredAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(registerdAtString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(news.title)
                .font(.headline)
            Text(news.body)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

private struct NewsRowPreviewWrapper: View {
    let news = News(
        newsId: "00000000-0000-0000-0000-000000000000",
        title: "アップデートしました",
        body: "ずんだもんと音声で会話できるようになったのだ！ぜひ試してみてほしいのだ〜。",
        registeredAt: Date())
    var body: some View {
        NewsRow(news: news)
    }
}

#Preview {
    NewsRowPreviewWrapper()
}
