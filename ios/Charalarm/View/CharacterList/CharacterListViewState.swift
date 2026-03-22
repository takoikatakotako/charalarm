import SwiftUI

@Observable class CharacterListViewState {
    var charaList: [Chara] = []
    var showingAlert = false
    var alertMessage = ""
    let apiRepository: APIRepository = APIRepository()
    let openURLRepository: OpenURLRepository = OpenURLRepository()

    func fetchCharacters() {
        Task { @MainActor in
            do {
                self.charaList = try await apiRepository.getCharaList()
            } catch {
                print(error)
                alertMessage = String(localized: "character-failed-to-get-the-character")
                self.showingAlert = true
            }
        }
    }
}
