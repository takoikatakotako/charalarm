import Foundation
import SwiftUI

@Observable class ContactViewState {
    private let discordRepository = DiscordRepository()
    private let keychainRepository = KeychainRepository()

    var id: String = ""
    var email: String = ""
    var message: String = ""

    var showingIndicator: Bool = false
    var showingAlert: Bool = false
    var alertEntity: AlertEntity?

    func onAppear() {
        Task { @MainActor in
            id = keychainRepository.getUserID() ?? ""
        }
    }

    func sendMessage() {
        guard 10 < message.count else {
            alertEntity = AlertEntity(title: "エラー", message: "10文字以上入力してください", actionText: "とじる")
            showingAlert = true
            return
        }

        var content = ""
        content += "**ID:**\n\(id)\n"
        content += "**Email:**\n\(email)\n"
        content += "**Message:**\n\(message)\n"

        let request = DiscordRequest(content: content)

        Task { @MainActor in
            showingIndicator = true
            do {
                try await discordRepository.sendMessageForContact(requestBody: request)
                alertEntity = AlertEntity(title: "", message: "送信が完了しました。", actionText: "とじる")
                showingAlert = true
            } catch {
                alertEntity = AlertEntity(title: "エラー", message: "送信に失敗しました。時間を空けて再度お試しください。", actionText: "とじる")
                showingAlert = true
            }
            showingIndicator = false
        }
    }
}
