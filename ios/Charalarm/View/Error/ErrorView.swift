import SwiftUI

struct ErrorView: View {
    @StateObject var viewState: ErrorViewState

    var body: some View {
        VStack {
            Image(R.image.zundamonSad.name)
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            Text("Sorry Unknown Error...")

            Button {
                viewState.reset()
            } label: {
                Text("Reset")
            }
        }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(viewState: ErrorViewState())
    }
}
