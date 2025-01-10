import Foundation

enum AlarmListViewAlertItem: Identifiable {
    case ad(UUID)
    case error(UUID, String)
    var id: UUID {
        switch self {
        case let .ad(id):
            return id
        case let .error(id, _):
            return id
        }
    }
}
