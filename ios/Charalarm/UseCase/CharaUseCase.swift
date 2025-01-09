import Foundation

protocol CharaUseCaseProtcol {
    func getSelfIntroductionUrlString(charaID: String) -> String
    func getCharaThumbnailUrlString(charaID: String) -> String
}

struct CharaUseCase: CharaUseCaseProtcol {
    private let apiRepository = APIRepository()
    private let fileRepository = FileRepository()
    private let userDefaultsRepository = UserDefaultsRepository()

    private let defaultsCharaID = "jp.zunko.zundamon"

    func getSelfIntroductionUrlString(charaID: String) -> String {
        return "\(EnvironmentVariableConfig.resourceEndpoint)/\(charaID)/self-introduction.caf"
    }

    func getCharaThumbnailUrlString(charaID: String) -> String {
        return "\(EnvironmentVariableConfig.resourceEndpoint)/\(charaID)/thumbnail.png"
    }

    func isExistDefaultCharaResources() -> Bool {
        do {
            let resourceData = try fileRepository.loadData(directoryName: defaultsCharaID, fileName: "resource.json")
            let localCharaResource: LocalCharaResource = try JSONDecoder().decode(LocalCharaResource.self, from: resourceData)

            for expression in localCharaResource.expressions {
                for imageFileName in expression.value.imageFileNames {
                    guard try fileRepository.isExistFile(directoryName: defaultsCharaID, fileName: imageFileName) else {
                        return false
                    }
                }
                for voiceFileName in expression.value.voiceFileNames {
                    guard try fileRepository.isExistFile(directoryName: defaultsCharaID, fileName: voiceFileName) else {
                        return false
                    }
                }
            }
            return true
        } catch {
            return false
        }
    }

    func copyToDefaultCharaDirectory() throws {
        guard let resourceFileURL = Bundle.main.url(forResource: "resource", withExtension: "json", subdirectory: "Resource/\(defaultsCharaID)"),
              let resourceData = try? Data(contentsOf: resourceFileURL),
              let localCharaResource: LocalCharaResource = try? JSONDecoder().decode(LocalCharaResource.self, from: resourceData) else {
            // TODO: エラー
            return
        }

        // 保存する
        for expression in localCharaResource.expressions {
            for imageFileName in expression.value.imageFileNames {
                guard let imageFileURL = Bundle.main.url(forResource: imageFileName, withExtension: "", subdirectory: "Resource/\(defaultsCharaID)"),
                      let imageData = try? Data(contentsOf: imageFileURL) else {
                    // TODO: エラーハンドリング
                    return
                }
                try fileRepository.saveFile(directoryName: defaultsCharaID, fileName: imageFileName, data: imageData)
            }

            for voiceFileName in expression.value.voiceFileNames {
                guard let voiceFileURL = Bundle.main.url(forResource: voiceFileName, withExtension: "", subdirectory: "Resource/\(defaultsCharaID)"),
                      let voiceData = try? Data(contentsOf: voiceFileURL) else {
                    // TODO: エラーハンドリング
                    return
                }
                try fileRepository.saveFile(directoryName: defaultsCharaID, fileName: voiceFileName, data: voiceData)
            }
        }

        try fileRepository.saveFile(directoryName: defaultsCharaID, fileName: "resource.json", data: resourceData)
    }

    func loadLocalCharaReesource() throws -> LocalCharaResource {
        guard let charaID = userDefaultsRepository.getCharaID() else {
            throw CharalarmError.clientError
        }

        let resourceData = try fileRepository.loadData(directoryName: charaID, fileName: "resource.json")
        let localCharaResource: LocalCharaResource = try JSONDecoder().decode(LocalCharaResource.self, from: resourceData)
        return localCharaResource
    }

    func fetchAndDownloadCharaResource() async throws {
        let charaID = userDefaultsRepository.getCharaID() ?? defaultsCharaID
        let chara = try await apiRepository.fetchCharacter(charaID: charaID)
        let localCharaResource: LocalCharaResource = LocalCharaResource(chara: chara)
        let data = try JSONEncoder().encode(localCharaResource)
        try fileRepository.saveFile(directoryName: charaID, fileName: "resource.json", data: data)
    }

    func checkUpdateCharaResource(charaID: String, updatedAt: String) async throws {
        let chara = try await apiRepository.fetchCharacter(charaID: charaID)
        let localCharaResource: LocalCharaResource = LocalCharaResource(chara: chara)

        // 新しい場合は保存
        guard localCharaResource.updatedAt > updatedAt else {
            return
        }
        let data = try JSONEncoder().encode(localCharaResource)
        try fileRepository.saveFile(directoryName: charaID, fileName: "resource.json", data: data)
    }
}
