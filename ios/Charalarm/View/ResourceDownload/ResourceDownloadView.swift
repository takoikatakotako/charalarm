import SwiftUI

struct ResourceDownloadView: View {
    @State var viewState: ResourceDownloadViewState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text(viewState.mainMessage)
            Text(viewState.progressMessage)

            if viewState.showDismissButton {
                Button {
                    dismiss()
                } label: {
                    Text(String(localized: "common-close"))
                }
            }
        }
        .onAppear {
            viewState.onAppear()
        }
    }
}

// struct ResourceDownloadView_Previews: PreviewProvider {
//    static var previews: some View {
//        ResourceDownloadView(viewState: <#ResourceDownloadViewState#>)
//    }
// }
