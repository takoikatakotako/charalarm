import SwiftUI

struct TutorialThirdView: View {
    var body: some View {
        TutorialPage(
            image: .tutorialAlarmScreenShot,
            imageHeight: 360,
            title: String(localized: "tutorial-did-you-get-a-call"),
            messages: [String(localized: "tutorial-you-can-set-multiple-alarms")]
        ) {
            NavigationLink {
                TutorialCharaListView()
            } label: {
                TutorialButtonContent(text: String(localized: "common-next"))
            }
        }
    }
}

#Preview {
    NavigationStack {
        TutorialThirdView()
    }
}
