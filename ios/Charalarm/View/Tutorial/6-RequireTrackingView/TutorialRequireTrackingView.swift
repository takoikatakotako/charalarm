import SwiftUI
import AppTrackingTransparency

struct TutorialRequireTrackingView: View {
    @State private var goNextView = false

    var body: some View {
        TutorialPage(
            image: .zundamonNormal,
            title: String(localized: "tutorial-customize-your-ads"),
            messages: [String(localized: "tutorial-charalarm-development-is-supported-by-advertising-revenue")]
        ) {
            Button {
                Task {
                    _ = await ATTrackingManager.requestTrackingAuthorization()
                    goNextView = true
                }
            } label: {
                TutorialButtonContent(text: String(localized: "common-next"))
            }
        }
        .navigationDestination(isPresented: $goNextView) {
            TutorialFinallyView()
        }
    }
}

#Preview {
    NavigationStack {
        TutorialRequireTrackingView()
    }
}
