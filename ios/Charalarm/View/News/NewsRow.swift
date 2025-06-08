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
            HStack {
                Text(registerdAtString)
                    .lineLimit(1)
                Spacer()
                Text(news.siteName)
                    .lineLimit(1)
            }
            Text(news.title)
                .lineLimit(2)
        }
    }
}

struct NewsRow_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        let news = News(
            newsId: 1,
            siteName: "Twitter",
            url: "google.com",
            title: "IntelliJでJavaのGradleのプロジェクトを作成する",
            description: "IntelliJでJavaのGradleのプロジェクトを作成する方法です。", registeredAt: Date())
        var body: some View {
            NewsRow(news: news)
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
