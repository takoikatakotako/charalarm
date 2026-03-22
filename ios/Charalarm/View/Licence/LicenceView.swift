import SwiftUI

struct LicenceView: View {
    @Environment(\.openURL) private var openURL
    @State var viewState: LicenceViewState

    var body: some View {
        List {
            Section(header: Text(String(localized: "license-character"))) {
                Button {
                    if let url = URL(string: ZunZunProjectURLString) {
                        openURL(url)
                    }
                } label: {
                    Text("ずんだもん")
                }
                .buttonStyle(.plain)
            }

            Section(header: Text(String(localized: "license-software"))) {
                Button {
                    if let url = URL(string: VoiceVoxURLString) {
                        openURL(url)
                    }
                } label: {
                    Text("VOICEVOX:ずんだもん")
                }
                .buttonStyle(.plain)
            }

            Section(header: Text(String(localized: "license-other"))) {
                Text(String(localized: "license-other-description"))
            }
        }
        .listStyle(.grouped)
    }
}

#Preview {
    NavigationStack {
        LicenceView(viewState: LicenceViewState())
    }
}
