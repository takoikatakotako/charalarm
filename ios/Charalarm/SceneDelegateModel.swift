import UIKit
import AVKit

class SceneDelegateModel {
    private let fileRepository: FileRepositoryProtcol
    private let userDefaultsRepository: UserDefaultsRepositoryProtocol
    private let authUseCase: AppUseCaseProtcol

    init(
        fileRepository: FileRepositoryProtcol = FileRepository(),
        userDefaultsRepository: UserDefaultsRepositoryProtocol = UserDefaultsRepository(),
        authUseCase: AppUseCaseProtcol = AppUseCase()
    ) {
        self.fileRepository = fileRepository
        self.userDefaultsRepository = userDefaultsRepository
        self.authUseCase = authUseCase
    }

    func registerDefaults() {
        userDefaultsRepository.registerDefaults()
    }
}
