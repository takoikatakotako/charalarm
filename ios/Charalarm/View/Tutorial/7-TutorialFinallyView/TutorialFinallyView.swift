import SwiftUI

struct TutorialFinallyView: View {
    var body: some View {
        TutorialPage(
            image: .zundamonSmile,
            messages: [String(localized: "tutorial-finally-please-allow-push-notificaion")]
        ) {
            Button {
                NotificationCenter.default.post(name: NSNotification.doneTutorial, object: nil, userInfo: nil)
            } label: {
                TutorialButtonContent(text: String(localized: "tutorial-go-to-home-screen"))
            }
        }
    }
}

#Preview {
    NavigationStack {
        TutorialFinallyView()
    }
}
