import Foundation
import FirebaseAppCheck
import FirebaseCore

/// Firebase App Check。App Attest で本物のアプリ・端末だと証明し、Firebase が出したトークンを API に付ける。
/// サーバはこのトークンで、スクリプトなどアプリ以外からの呼び出しを見分ける
enum AppCheckRepository {
    /// トークンを入れるヘッダ（サーバの handler.AppCheckHeader と同じ）
    static let headerName = "X-Firebase-AppCheck"

    /// FirebaseApp.configure() の前に呼ぶ
    static func configure() {
        AppCheck.setAppCheckProviderFactory(CharalarmAppCheckProviderFactory())
    }

    /// 起動したときに先に取っておく。はじめての証明は時間がかかるので、着信の会話を待たせないため
    static func prefetch() {
        Task { _ = await header() }
    }

    /// API に付けるヘッダ。取れなければ空（サーバは今は記録するだけなので、そのまま呼ぶ）
    static func header() async -> [String: String] {
        do {
            let token = try await AppCheck.appCheck().token(forcingRefresh: false)
            return [headerName: token.token]
        } catch {
            CharalarmLogger.breadcrumb("App Check: トークンを取れなかった \(error.localizedDescription)")
            return [:]
        }
    }
}

/// Simulator は App Attest を使えないので、デバッグ用の仕組みにする（コンソールに出るトークンを Firebase に登録して使う）
final class CharalarmAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if targetEnvironment(simulator)
        return AppCheckDebugProvider(app: app)
        #else
        return AppAttestProvider(app: app)
        #endif
    }
}
