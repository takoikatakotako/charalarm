import SwiftUI

struct NewsListView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject(initialValue: NewsListViewModel()) var viewModel: NewsListViewModel

    var body: some View {
        NavigationView {
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
            .navigationBarTitle(String(localized: "news-news"), displayMode: .inline)
            .navigationBarItems(leading:
                                    Button(action: {
                                        presentationMode.wrappedValue.dismiss()
                                    }) {
                                        Image(R.image.commonIconClose.name)
                                            .renderingMode(.template)
                                            .foregroundColor(Color(R.color.charalarmDefaultGray.name))
                                    }
            )
        }.onAppear {
            viewModel.fetchNews()
        }.alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text(""), message: Text(viewModel.alertMessage), dismissButton: .default(Text(String(localized: "common-close"))))
        }
    }
}

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsListView()
    }
}
