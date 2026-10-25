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
    /// 電話以外で出す画面 (起動の確認の結果、チュートリアルの完了・リセットで変わる)。電話が終わったらここに戻る
    private var launchDestination: RootViewType?

    func onAppear() {
        // 電話に出てアプリが起動したときは、起動の確認より先に電話の画面を出す
        syncWithAnsweredCall()
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
        showDestination(.top)
    }

    func didReset() {
        showDestination(.tutorial)
    }

    /// 起動の確認が終わった
    private func finishLaunching(_ destination: RootViewType) {
        showDestination(destination)
    }

    /// 電話以外の画面に移る。電話中なら電話の画面のままにし、行き先を覚えて電話が終わってから出す
    private func showDestination(_ destination: RootViewType) {
        launchDestination = destination
        guard AnsweredCallStore.shared.call == nil else { return }
        withAnimation(.linear(duration: 1)) {
            type = destination
        }
    }

    /// 画面を通話の状態に合わせる。電話に出ていれば電話の画面に、電話が終わっていれば元の画面に戻す。
    /// 知らせ (応答・終話) を受け取る準備をする前に状態が変わっていても、これで合わせられる
    func syncWithAnsweredCall() {
        if let call = AnsweredCallStore.shared.call {
            charaID = call.charaID
            charaName = call.charaName
            callUUID = call.callUUID
            // 会話対応キャラは音声会話画面へ、それ以外は従来の録音再生へ
            type = call.conversation ? .conversation : .calling
        } else if type == .conversation || type == .calling {
            // 起動の確認がまだ終わっていなければ、終わるまでロゴを出す
            withAnimation(.linear(duration: 1)) {
                type = launchDestination ?? .loading
            }
        }
    }
}
