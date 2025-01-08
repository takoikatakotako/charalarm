import Foundation

struct UserInfoAlertItem: Identifiable, Hashable {
    var id: Self {
        return self
    }
    let message: String
}
