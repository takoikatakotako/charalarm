import SwiftUI
import StoreKit
import SDWebImageSwiftUI

struct CharaProfileView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var viewState: CharaProfileViewState

    var body: some View {
        GeometryReader { geometory in
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    WebImage(url: URL(string: viewState.charaThumbnailUrlString))
                        .resizable()
                        .placeholder {
                            Image(R.image.characterPlaceholder.name)
                                .resizable()
                        }
                        .animation(.easeInOut, value: 0.5)
                        .transition(.fade)
                        .frame(width: geometory.size.width, height: geometory.size.width)
                        .scaledToFill()

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
                            MenuItem(imageName: R.image.profileCall.name)
                        }

                        Button(action: {
                            viewState.showSelectAlert = true
                        }) {
                            MenuItem(imageName: R.image.profileCheck.name)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading:
                BackBarButton {
                    presentationMode.wrappedValue.dismiss()
                }
        )
        .onAppear {
            viewState.fetchCharacter()
        }
        .alert(isPresented: $viewState.showSelectAlert) {
            Alert(
                title: Text(String(localized: "profile-character-selection")),
                message: Text(String(localized: "profile-want-to-call-this-character")),
                primaryButton: .default(Text(String(localized: "common-close"))) {
                }, secondaryButton: .default(Text(String(localized: "profile-yes"))) {
                    viewState.selectCharacter()
                })
        }
        .sheet(isPresented: $viewState.showCallView) {
            CallView(viewState: CallViewState(charaDomain: viewState.chara?.charaID ?? "", charaName: viewState.chara?.name ?? ""))
        }
        .sheet(
            isPresented: $viewState.showCallView,
            onDismiss: {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
            }) {
                CallView(viewState: CallViewState(charaDomain: viewState.chara?.charaID ?? "", charaName: viewState.chara?.name ?? ""))
            }
            .fullScreenCover(isPresented: $viewState.showingResourceDownloadView) {
                ResourceDownloadView(viewState: ResourceDownloadViewState(charaID: viewState.charaID))
            }
    }
}

struct ProfileView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        var body: some View {
            CharaProfileView(viewState: CharaProfileViewState(charaID: "com.example.xxx"))
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
