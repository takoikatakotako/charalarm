import UIKit
import AVKit

class SceneDelegateModel {
    private let fileRepository: FileRepositoryProtocol
    private let userDefaultsRepository: UserDefaultsRepositoryProtocol
    private let authUseCase: AppUseCaseProtocol

    init(
        fileRepository: FileRepositoryProtocol = FileRepository(),
        userDefaultsRepository: UserDefaultsRepositoryProtocol = UserDefaultsRepository(),
        authUseCase: AppUseCaseProtocol = AppUseCase()
    ) {
        self.fileRepository = fileRepository
        self.userDefaultsRepository = userDefaultsRepository
        self.authUseCase = authUseCase
    }

    func registerDefaults() {
        userDefaultsRepository.registerDefaults()
    }
}
