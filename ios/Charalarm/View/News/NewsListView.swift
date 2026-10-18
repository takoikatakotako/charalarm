import SwiftUI

struct NewsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewState = NewsListViewState()

    var body: some View {
        NavigationStack {
            List(viewState.newsList) { news in
                NewsRow(news: news)
            }
            .navigationTitle(String(localized: "news-news"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseBarButton {
                        dismiss()
                    }
                }
            }
        }.onAppear {
            viewState.fetchNews()
        }.alert("", isPresented: $viewState.showingAlert) {
            Button(String(localized: "common-close")) {}
        } message: {
            Text(viewState.alertMessage)
        }
    }
}

#Preview {
    NewsListView()
}
