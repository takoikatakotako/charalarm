import SwiftUI

struct TutorialCharaListView: View {
    var body: some View {
        TutorialPage(
            image: .tutorialCharaListScreenShot,
            imageHeight: 360,
            messages: [String(localized: "tutorial-you-can-see-the-characters"), String(localized: "tutorial-please-choose-your-favorite-character")]
        ) {
            NavigationLink {
                TutorialAcceptPrivacyPolicyView()
            } label: {
                TutorialButtonContent(text: String(localized: "common-next"))
            }
        }
    }
}

#Preview {
    NavigationStack {
        TutorialCharaListView()
    }
}
