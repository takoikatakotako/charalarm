import SwiftUI
import CallKit
import UIKit
import AVFoundation

@Observable class CallingViewState {
    let charaID: String?
    let charaName: String?
    let callUUID: UUID?

    init(charaID: String?, charaName: String?, callUUID: UUID?) {
        self.charaID = charaID
        self.charaName = charaName
        self.callUUID = callUUID
    }

    private let controller = CXCallController()

    func endCall() {
        guard let callUUID = callUUID else {
            CharalarmLogger.error("endCall failed: callUUID is nil", error: nil)
            return
        }

        let endCallAction = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: endCallAction)
        controller.request(transaction) { error in
            if let error = error {
                CharalarmLogger.critical("end call error", error: error)
            }
        }
    }
}
