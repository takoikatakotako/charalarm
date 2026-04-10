import SwiftUI
import FirebaseCore

@main
struct CharalarmApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView(viewState: RootViewState())
        }
    }
}
