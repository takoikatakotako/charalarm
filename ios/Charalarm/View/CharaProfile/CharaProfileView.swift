import SwiftUI
import StoreKit
import SDWebImageSwiftUI

struct CharaProfileView: View {
    @Environment(\.requestReview) private var requestReview
    @State var viewState: CharaProfileViewState

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Group {
                    if let chara = viewState.chara, case .vrm(let modelFileURL) = viewState.selectedAppearance {
                        CharaVRMView(charaID: chara.charaID, modelFileURL: modelFileURL)
                    } else {
                        WebImage(url: URL(string: viewState.charaThumbnailUrlString)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(.characterPlaceholder)
                                .resizable()
                        }
                        .scaledToFill()
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()

                // 3D とイラストの両方があるキャラは、見た目を選べる
                if let chara = viewState.chara, chara.appearances.count > 1 {
                    Picker("", selection: Binding(
                        get: { viewState.selectedAppearance?.kind ?? .illustration },
                        set: { viewState.selectAppearance(kind: $0) }
                    )) {
                        ForEach(chara.appearances.map(\.kind), id: \.self) { kind in
                            Text(kind == .vrm ? String(localized: "profile-appearance-3d") : String(localized: "profile-appearance-illustration"))
                                .tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(16)
                }

                VStack(spacing: 0) {
                    CharaProfileRow(title: String(localized: "profile-name"), text: viewState.chara?.name ?? "", url: nil)
                    CharaProfileRow(title: String(localized: "profile-profile"), text: viewState.chara?.description ?? "", url: nil)
                    if let profiles = viewState.chara?.profiles {
                        ForEach(profiles, id: \.hashValue) { profile in
                            CharaProfileRow(title: profile.title, text: profile.name, url: profile.url)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button {
                    guard viewState.chara != nil else { return }
                    viewState.showCallView = true
                } label: {
                    Label(String(localized: "profile-listen-call"), systemImage: "phone.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)

                Button {
                    viewState.showSelectAlert = true
                } label: {
                    Label(String(localized: "profile-select"), systemImage: "checkmark")
                }
                .buttonStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .navigationTitle(viewState.chara?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewState.fetchCharacter()
        }
        .alert(String(localized: "profile-character-selection"), isPresented: $viewState.showSelectAlert) {
            Button(String(localized: "common-close"), role: .cancel) {}
            Button(String(localized: "profile-yes")) {
                viewState.selectCharacter()
            }
        } message: {
            Text(String(localized: "profile-want-to-call-this-character"))
        }
        .sheet(isPresented: $viewState.showCallView, onDismiss: {
            requestReview()
        }) {
            CallView(viewState: CallViewState(charaDomain: viewState.chara?.charaID ?? "", charaName: viewState.chara?.name ?? ""))
        }
        .fullScreenCover(isPresented: $viewState.showingResourceDownloadView) {
            ResourceDownloadView(viewState: ResourceDownloadViewState(charaID: viewState.charaID))
        }
    }
}

#Preview {
    NavigationStack {
        CharaProfileView(viewState: CharaProfileViewState(charaID: "com.example.xxx"))
    }
}
