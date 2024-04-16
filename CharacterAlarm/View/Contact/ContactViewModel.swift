import Foundation

import UIKit
import SwiftUI

class ContactViewState: ObservableObject {
    private let discordRepository = DiscordRepository()
    private let keychainRepository = KeychainRepository()
    
    @Published var id: String = ""
    @Published var email: String = ""
    @Published var message: String = ""
    
    @Published var showingAlert: Bool = false
    @Published var alertEntity: AlertEntity?

    func onAppear() {
        id = keychainRepository.getUserID() ?? ""
    }
    
    func sendMessage() {
        guard 20 < message.count else {
            alertEntity = AlertEntity(title: "エラー", message: "sdfsdfs", actionText: "とじる")
            showingAlert = true
            return
        }

        var content = ""
        content += "**ID:**\n\(id)\n"
        content += "**Email:**\n\(email)\n"
        content += "**Message:**\n\(message)\n"

        let request = DiscordRequest(content: content)
        
        Task { @MainActor in
            do {
                try await discordRepository.sendMessageForContact(requestBody: request)
                alertEntity = AlertEntity(title: "エラー", message: "送信が完了しました。", actionText: "とじる")
                showingAlert = true
            } catch {
                alertEntity = AlertEntity(title: "エラー", message: "送信に失敗しました。時間を空けて再度お試しください。", actionText: "とじる")
                showingAlert = true
            }
        }
    }
}
