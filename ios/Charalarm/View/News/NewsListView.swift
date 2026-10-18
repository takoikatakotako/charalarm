import SwiftUI

struct NewsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NewsListViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.newsList) { news in
                NewsRow(news: news)
            }
            .navigationTitle(String(localized: "news-news"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(.commonIconClose)
                            .renderingMode(.template)
                            .foregroundStyle(Color(.charalarmDefaultGray))
                    }
                }
            }
        }.onAppear {
            viewModel.fetchNews()
        }.alert("", isPresented: $viewModel.showingAlert) {
            Button(String(localized: "common-close")) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

#Preview {
    NewsListView()
}
