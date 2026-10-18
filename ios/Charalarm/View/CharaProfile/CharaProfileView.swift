import SwiftUI
import StoreKit
import SDWebImageSwiftUI

struct CharaProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State var viewState: CharaProfileViewState

    var body: some View {
        GeometryReader { geometory in
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    if let chara = viewState.chara, case .vrm(let modelFileURL) = viewState.selectedAppearance {
                        CharaVRMView(charaID: chara.charaID, modelFileURL: modelFileURL)
                            .frame(width: geometory.size.width, height: geometory.size.width)
                    } else {
                        WebImage(url: URL(string: viewState.charaThumbnailUrlString)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(.characterPlaceholder)
                                .resizable()
                        }
                        .frame(width: geometory.size.width, height: geometory.size.width)
                        .scaledToFill()
                    }

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
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    CharaProfileRow(title: String(localized: "profile-name"), text: viewState.chara?.name ?? "", url: nil)
                    CharaProfileRow(title: String(localized: "profile-profile"), text: viewState.chara?.description ?? "", url: nil)

                    if let profiles = viewState.chara?.profiles {
                        ForEach(profiles, id: \.hashValue) { profile in
                            CharaProfileRow(title: profile.title, text: profile.name, url: profile.url)
                        }
                    }

                    Spacer()
                        .frame(height: 60)
                }

                HStack {
                    Spacer()

                    VStack {
                        Spacer()
                        Button(action: {
                            guard viewState.chara?.charaID != nil || viewState.chara?.name != nil else {
                                return
                            }
                            viewState.showCallView = true
                        }) {
                            MenuItem(image: .profileCall)
                        }

                        Button(action: {
                            viewState.showSelectAlert = true
                        }) {
                            MenuItem(image: .profileCheck)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackBarButton {
                    dismiss()
                }
            }
        }
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
        .sheet(isPresented: $viewState.showCallView) {
            CallView(viewState: CallViewState(charaDomain: viewState.chara?.charaID ?? "", charaName: viewState.chara?.name ?? ""))
        }
        .sheet(
            isPresented: $viewState.showCallView,
            onDismiss: {
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
    CharaProfileView(viewState: CharaProfileViewState(charaID: "com.example.xxx"))
}
