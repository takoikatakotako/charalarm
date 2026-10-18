import SwiftUI

struct TutorialAcceptPrivacyPolicyView: View {
    @State var viewState = TutorialAcceptPrivacyPolicyViewState()

    var body: some View {
        TutorialPage(
            image: .zundamonNormal,
            messages: [String(localized: "tutorial-please-accept-the-privacy-policy")]
        ) {
            if let url = URL(string: PrivacyPolicyUrlString) {
                Link(String(localized: "tutorial-open-the-privacy-policy"), destination: url)
                    .font(.body.weight(.semibold))
            }
        } footer: {
            Button {
                viewState.signUp()
            } label: {
                TutorialButtonContent(text: String(localized: "tutorial-agree-with-the-privacy-policy"))
            }
            .disabled(viewState.creatingAccount)
        }
        .overlay {
            if viewState.creatingAccount {
                ProgressView()
                    .controlSize(.large)
                    .padding(32)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .alert("", isPresented: $viewState.showingAlert) {
            Button(String(localized: "common-close")) {}
        } message: {
            Text(viewState.alertMessage)
        }
        .navigationDestination(isPresented: $viewState.accountCreated) {
            TutorialRequireTrackingView()
        }
    }
}

#Preview {
    NavigationStack {
        TutorialAcceptPrivacyPolicyView()
    }
}
