import SwiftUI
import CallKit
import UIKit
import AVFoundation

class CallingViewState: ObservableObject {
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
            fatalError("Message")
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
