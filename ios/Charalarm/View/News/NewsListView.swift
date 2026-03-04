import SwiftUI

struct NewsListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewsListViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.newsList) { news in
                Button {
                    guard let url = URL(string: news.url) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    NewsRow(news: news)
                }
            }
            .navigationTitle(String(localized: "news-news"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(R.image.commonIconClose.name)
                            .renderingMode(.template)
                            .foregroundColor(Color(R.color.charalarmDefaultGray.name))
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

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsListView()
    }
}
