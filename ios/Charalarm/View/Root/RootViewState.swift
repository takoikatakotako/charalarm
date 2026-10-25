import SwiftUI
import FirebaseAuth

@MainActor @Observable final class RootViewState {
    var type: RootViewType = .loading

    var charaID: String?
    var charaName: String?
    var callUUID: UUID?

    private let apiRepository = APIRepository()
    private let appUseCase = AppUseCase()
    private let charaUseCase = CharaUseCase()
    private let userDefaultsRepository = UserDefaultsRepository()
    private let fileRepository: FileRepositoryProtocol = FileRepository()

    /// 起動の確認を始めたか (一度だけ行う)
    private var hasStartedLaunching = false
    /// 起動の確認が終わったときに出す画面。電話中に終わったら、電話が終わってから出す
    private var launchDestination: RootViewType?

    func onAppear() {
        // 電話に出てアプリが起動したときは、起動の確認より先に電話の画面を出す
        showAnsweredCallIfNeeded()
        guard !hasStartedLaunching else { return }
        hasStartedLaunching = true

        Task { @MainActor in
            do {
                // TODO: ネットワークチェック

                // メンテナンス中か確認
                let isMaintenance = try await apiRepository.fetchMaintenance()
                if isMaintenance {
                    finishLaunching(.maintenance)
                    return
                }

                // アップデートが必要か確認
                let requireVersion = try await apiRepository.fetchRequireVersion()
                if requireVersion > appUseCase.appVersion {
                    finishLaunching(.updateRequire)
                    return
                }

                // Firebaseログイン
                try await Auth.auth().signInAnonymously()

                // UserDefaults に初期値を入れる
                userDefaultsRepository.registerDefaults()

                // 初期ファイルが配置済みか確認する
                let exists: Bool = charaUseCase.isExistDefaultCharaResources()
                if exists == false {
                    try charaUseCase.copyToDefaultCharaDirectory()
                }

                // デコードできるかチェックする
                if let localCharaResource = try? charaUseCase.loadLocalCharaResource() {
                    // 最新更新できるかチェックする
                    try? await charaUseCase.checkUpdateCharaResource(charaID: localCharaResource.charaID, updatedAt: localCharaResource.updatedAt)
                } else {
                    // 最新版を落とす
                    try? await charaUseCase.fetchAndDownloadCharaResource()
                }

                // チュートリアルの状態を確認
                if appUseCase.isDoneTutorial {
                    finishLaunching(.top)
                } else {
                    finishLaunching(.tutorial)
                }
            } catch {
                CharalarmLogger.error("起動時の確認に失敗", error: error)
                finishLaunching(.error)
            }
        }
    }

    func doneTutorial() {
        withAnimation(.linear(duration: 1)) {
            type = .top
        }
    }

    func didReset() {
        withAnimation(.linear(duration: 1)) {
            type = .tutorial
        }
    }

    /// 起動の確認が終わった。電話中なら電話の画面のままにし、電話が終わってから出す
    private func finishLaunching(_ destination: RootViewType) {
        launchDestination = destination
        guard AnsweredCallStore.shared.call == nil else { return }
        withAnimation(.linear(duration: 1)) {
            type = destination
        }
    }

    /// 電話に出ていたら、電話の画面にする
    func showAnsweredCallIfNeeded() {
        guard let call = AnsweredCallStore.shared.call else { return }
        charaID = call.charaID
        charaName = call.charaName
        callUUID = call.callUUID
        // 会話対応キャラは音声会話画面へ、それ以外は従来の録音再生へ
        type = call.conversation ? .conversation : .calling
    }

    func endCall() {
        // 起動の確認がまだ終わっていなければ、終わるまでロゴを出す
        withAnimation(.linear(duration: 1)) {
            type = launchDestination ?? .loading
        }
    }
}
