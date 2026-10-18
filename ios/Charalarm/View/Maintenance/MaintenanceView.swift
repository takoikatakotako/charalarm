import SwiftUI

struct MaintenanceView: View {
    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "maintenance-title"), systemImage: "wrench.and.screwdriver")
        } description: {
            Text(String(localized: "maintenance-message"))
        } actions: {
            if let url = URL(string: OfficialTwitterUrlString) {
                Link(String(localized: "maintenance-open-x"), destination: url)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    MaintenanceView()
}
