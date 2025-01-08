import SwiftUI
import UniformTypeIdentifiers

struct UserInfoView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @StateObject var viewState: UserInfoViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading) {
                Text(String(localized: "user-info-user-name"))
                    .font(Font.body.bold())

                Text(viewState.userID)
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading) {
                Text("PremiumPlan")
                    .font(Font.body.bold())

                Text(viewState.premiumPlan)
                    .textSelection(.enabled)
            }

            if viewState.showHidenInfos {
                VStack(alignment: .leading) {
                    Text("AuthToken")
                        .font(Font.body.bold())

                    Text(viewState.authToken)
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading) {
                    Text("PushTokenEndpoint")
                        .font(Font.body.bold())
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Text(viewState.userInfo?.iOSPlatformInfo.pushTokenSNSEndpoint ?? "Loading")
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading) {
                    Text("VoIPPushTokenEndpoint")
                        .font(Font.body.bold())
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Text(viewState.userInfo?.iOSPlatformInfo.voIPPushTokenSNSEndpoint ?? "Loading")
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading) {
                    Text("PushToken")
                        .font(Font.body.bold())
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Text(viewState.pushToken ?? "empty")
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading) {
                    Text("VoIPPushToken")
                        .font(Font.body.bold())
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Text(viewState.voipPushToken ?? "empty")
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading) {
                    Text("PremiumPlan@UserDefaults")
                        .font(Font.body.bold())
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Text(viewState.premiumPlanAtUserDefaults)
                        .textSelection(.enabled)
                }
            }

            Spacer()

            Button {
                viewState.tapHidenButton()
            } label: {
                Color.clear
                    .frame(height: 40)
                    .frame(minWidth: 0, maxWidth: .infinity)

            }
        }
        .onAppear {
            viewState.fetchUserInfo()
        }
        .alert(item: $viewState.alert, content: { item in
            Alert(title: Text("Error"), message: Text(item.message), dismissButton: .default(Text("Close")))
        })
        .padding()
        .navigationBarTitle(String(localized: "user-info-user-nfo"), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading:
                BackBarButton {
                    presentationMode.wrappedValue.dismiss()
                }
        )
    }
}

struct UserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        UserInfoView(viewState: UserInfoViewState())
    }
}
