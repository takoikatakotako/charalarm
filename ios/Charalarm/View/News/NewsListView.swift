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
                        Image(R.image.commonIconClose.name)
                            .renderingMode(.template)
                            .foregroundStyle(Color(R.color.charalarmDefaultGray.name))
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
