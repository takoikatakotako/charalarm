import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    @ViewBuilder
    var body: some View {
        if appState.settingState.doneTutorial {
            ContentView()
        } else {
            TutorialHolderView()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
