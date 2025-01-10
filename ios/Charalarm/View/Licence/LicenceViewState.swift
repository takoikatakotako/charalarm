import UIKit
import SwiftUI

class LicenceViewState: ObservableObject {
    func openZunZunProject() {
        guard let url = URL(string: ZunZunProjectURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func openVoiceVox() {
        guard let url = URL(string: VoiceVoxURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
