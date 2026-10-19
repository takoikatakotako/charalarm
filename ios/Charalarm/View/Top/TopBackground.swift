import SwiftUI

enum TopBackground: String, CaseIterable, Identifiable {
    static let defaultsKey = "TOP_BACKGROUND"

    case washitsu
    case office
    case bedroom
    case livingRoom
    case cafe
    case library

    var id: String { rawValue }

    var imageName: String {
        switch self {
        case .washitsu: "background"
        case .office: "background-office"
        case .bedroom: "background-bedroom"
        case .livingRoom: "background-living-room"
        case .cafe: "background-cafe"
        case .library: "background-library"
        }
    }

    var title: String {
        switch self {
        case .washitsu: String(localized: "background-washitsu")
        case .office: String(localized: "background-office")
        case .bedroom: String(localized: "background-bedroom")
        case .livingRoom: String(localized: "background-living-room")
        case .cafe: String(localized: "background-cafe")
        case .library: String(localized: "background-library")
        }
    }
}
