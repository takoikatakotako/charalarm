import SwiftUI
import AVFoundation
import AdSupport
import AppTrackingTransparency

enum TopViewModelAlert: Identifiable {
    case failedToGetCharacterInformation
    case failedToGetCharacterSelectionInformation
    case failedToGetCharactersResources
    case failedToSetCharacterImage
    case thisFeatureIsNotAvailableInYourRegion
    var id: Int {
        return hashValue
    }
}

enum TopViewModelSheet: Identifiable {
    case newsList
    case characterList
    case alarmList
    case config
    var id: Int {
        return hashValue
    }
}

class TopViewState: ObservableObject {
    @Published var charaImage = UIImage()
    @Published var alert: TopViewModelAlert?
    @Published var sheet: TopViewModelSheet?
    private let userDefaultsRepository: UserDefaultsRepository = UserDefaultsRepository()
    private let fileHandler: FileRepositoryProtcol = FileRepository()

    private let localCharaResourceUseCase = LocalCharaResourceUseCase()

    var audioPlayer: AVAudioPlayer?

    func onAppear() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        guard let charaID = userDefaultsRepository.getCharaID() else {
            self.alert = .failedToGetCharacterSelectionInformation
            return
        }

        guard let resource = try? localCharaResourceUseCase.loadCharaResource(charaID: charaID) else {
            self.alert = .failedToGetCharactersResources
            return
        }

        guard let key = resource.expressions.keys.randomElement() else {
            return
        }

        setCharaImage(charaDomain: charaID, resource: resource, key: key)
    }

    func newsButtonTapped() {
        sheet = .newsList
    }

    func characterListButtonTapped() {
        sheet = .characterList
    }

    func alarmButtonTapped() {
        guard Locale.current.region?.identifier != "CN" else {
            alert = .thisFeatureIsNotAvailableInYourRegion
            return
        }
        sheet = .alarmList
    }

    func configButtonTapped() {
        sheet = .config
    }

    func tapped() {
        guard let charaDomain = userDefaultsRepository.getCharaID() else {
            self.alert = .failedToGetCharacterSelectionInformation
            return
        }

        guard let resource = try? localCharaResourceUseCase.loadCharaResource(charaID: charaDomain) else {
            self.alert = .failedToGetCharactersResources
            return
        }

        guard let key = resource.expressions.keys.randomElement() else {
            return
        }

        setCharaImage(charaDomain: charaDomain, resource: resource, key: key)
        playCharaVoice(charaDomain: charaDomain, resource: resource, key: key)
    }

    //    func featchCharacter(charaDomain: String) async throws -> Character {
    //        Task {
    //            let
    //        }
    //        charaRepository.fetchCharacter(charaDomain: charaDomain) { result in
    //            switch result {
    //            case let .success(character):
    //                completion(character)
    //            case .failure:
    //                self.alert = .failedToGetCharacterInformation
    //            }
    //        }
    //    }

    func updateChara(charaID: String?) {
        guard let charaID = charaID else {
            DispatchQueue.main.async {
                self.alert = .failedToGetCharacterSelectionInformation
            }
            return
        }

        guard let resource = try? localCharaResourceUseCase.loadCharaResource(charaID: charaID) else {
            DispatchQueue.main.async {
                self.alert = .failedToGetCharactersResources
            }
            return
        }

        guard let key = resource.expressions.keys.randomElement() else {
            return
        }

        setCharaImage(charaDomain: charaID, resource: resource, key: key)

        //        guard let charaDomain = userDefaultsRepository.getCharaDomain() else {
        //            DispatchQueue.main.async {
        //                self.alert = .failedToGetCharacterSelectionInformation
        //            }
        //            return
        //        }
        //
        //        guard let resource = getResource(charaDomain: charaDomain) else {
        //            DispatchQueue.main.async {
        //                self.alert = .failedToGetCharactersResources
        //            }
        //            return
        //        }
        //
        //        guard let key = resource.expression.keys.randomElement() else {
        //            return
        //        }
        //
        //        setCharaImage(charaDomain: charaDomain, resource: resource, key: key)
    }

    //    private func getResource(charaDomain: String) -> Resource? {
    //        guard let data = try? fileHandler.loadData(directoryName: charaDomain, fileName: "resource.json") else {
    //            return nil
    //        }
    //        let decoder = JSONDecoder()
    //        decoder.dateDecodingStrategy = .iso8601
    //        guard let resource = try? decoder.decode(Resource.self, from: data) else {
    //            return nil
    //        }
    //        return resource
    //    }
    //
    private func setCharaImage(charaDomain: String, resource: LocalCharaResource, key: String) {
        guard let imageName = resource.expressions[key]?.imageFileNames.randomElement() else {
            return
        }

        do {
            let data = try fileHandler.loadData(directoryName: charaDomain, fileName: imageName)
            charaImage = UIImage(data: data)!
        } catch {
            DispatchQueue.main.async {
                self.alert = .failedToSetCharacterImage
            }
        }
    }

    private func playCharaVoice(charaDomain: String, resource: LocalCharaResource, key: String) {
        guard let voiceName = resource.expressions[key]?.voiceFileNames.randomElement() else {
            return
        }

        do {
            let data = try fileHandler.loadData(directoryName: charaDomain, fileName: voiceName)
            audioPlayer = try? AVAudioPlayer(data: data)
            audioPlayer?.play()
        } catch {
            print(error)
        }
    }
}
