import SwiftUI

struct TutorialHolderView: View {
    // 1. TutorialIntroductionView
    // 2. TutorialCallView
    // 3. TutorialThirdView
    // 4. TutorialCharaListView
    // 5. TutorialAcceptPrivacyPolicyView
    // 6. TutorialRequireTrackingView
    // 7. TutorialFinallyView
    var body: some View {
        NavigationView {
            TutorialIntroductionView()
        }
    }
}

struct TutorialHolderView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialHolderView()
    }
}
