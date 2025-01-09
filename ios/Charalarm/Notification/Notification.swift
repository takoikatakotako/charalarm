import Foundation

extension NSNotification {
    static let setChara = NSNotification.Name("setChara")
    static let didReset = NSNotification.Name("didReset")
    static let doneTutorial = NSNotification.Name("doneTutorial")
    static let answerCall = NSNotification.Name("answerCall")
    static let endCall = NSNotification.Name("endCall")

    // setChara
    static let setCharaUserInfoKeyCharaID = "charaID"

    // answerCall
    static let answerCallUserInfoKeyCharaID = "charaID"
    static let answerCallUserInfoKeyCharaName = "charaName"
    static let answerCallUserInfoKeyCallUUID = "callUUID"
}
