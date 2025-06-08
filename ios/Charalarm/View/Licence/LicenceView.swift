import SwiftUI

struct LicenceView: View {
    @StateObject var viewState: LicenceViewState

    var body: some View {
        List {
            Section(header: Text(String(localized: "license-character"))) {
                Button {
                    viewState.openZunZunProject()
                } label: {
                    Text("ずんだもん")
                }
                .buttonStyle(.plain)
            }

            Section(header: Text(String(localized: "license-software"))) {
                Button {
                    viewState.openZunZunProject()
                } label: {
                    Text("VOICEVOX:ずんだもん")
                }
                .buttonStyle(.plain)
            }

            Section(header: Text(String(localized: "license-other"))) {
                Text(String(localized: "license-other-description"))
            }
        }
        .listStyle(GroupedListStyle())
    }
}

struct LicenceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LicenceView(viewState: LicenceViewState())
        }
    }
}
