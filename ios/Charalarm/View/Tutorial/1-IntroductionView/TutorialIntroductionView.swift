import SwiftUI

struct TutorialIntroductionView: View {
    var body: some View {
        TutorialPage(
            image: .zundamonNormal,
            title: String(localized: "tutorial-welcome-to-charalarm"),
            messages: [String(localized: "tutorial-this-is-an-app"), String(localized: "tutorial-let-us-try-it-now")]
        ) {
            NavigationLink {
                TutorialCallView()
            } label: {
                TutorialButtonContent(text: String(localized: "tutorial-get-a-call"))
            }
        }
    }
}

#Preview {
    NavigationStack {
        TutorialIntroductionView()
    }
}
