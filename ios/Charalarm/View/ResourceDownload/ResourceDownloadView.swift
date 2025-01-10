import SwiftUI

struct ResourceDownloadView: View {
    @StateObject var viewState: ResourceDownloadViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        VStack {
            Text(viewState.mainMessage)
            Text(viewState.progressMessage)

            if viewState.showDismissButton {
                Button {
                    presentationMode.wrappedValue.dismiss()
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
