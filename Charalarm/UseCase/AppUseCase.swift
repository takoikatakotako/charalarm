import Foundation

protocol AppUseCaseProtcol {
    var isDoneTutorial: Bool {get}
    var appVersion: String {get}
    var appBuild: String {get}
}

struct AppUseCase: AppUseCaseProtcol {
    let keychainRepository: KeychainRepositoryProtcol

    init(keychainRepository: KeychainRepositoryProtcol = KeychainRepository()) {
        self.keychainRepository = keychainRepository
    }

    var isDoneTutorial: Bool {
        // ユーザー名とパスワードを取得
        let userID = keychainRepository.getUserID()
        let authToken = keychainRepository.getAuthToken()

        // 匿名ユーザー名、パスワードが登録されていればチュートリアル完了
        return userID != nil && authToken != nil
    }

    var appVersion: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            fatalError("Can't get version")
        }
        return version
    }

    var appBuild: String {
        guard let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            fatalError("Can't get build")
        }
        return build
    }
}
