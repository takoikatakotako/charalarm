import SwiftUI
import FirebaseCore

@main
struct CharalarmApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // アイコンの UI テストは、起動時のサーバ確認・ログインに依存させない。
            if ProcessInfo.processInfo.arguments.contains("--ui-test-settings") {
                ConfigView(viewState: ConfigViewState())
            } else {
                RootView(viewState: RootViewState())
            }
            #else
            RootView(viewState: RootViewState())
            #endif
        }
    }
}
