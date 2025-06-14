import SwiftUI
import SDWebImageSwiftUI

struct ConfigView: View {
    @StateObject var viewState: ConfigViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List {
                    Section(
                        header:
                            Text(String(localized: "config-user-info"))
                            .foregroundStyle(Color(.appMainText))
                    ) {
                        NavigationLink(destination: UserInfoView(viewState: UserInfoViewState())) {
                            Text(String(localized: "config-user-info"))
                                .foregroundColor(Color(R.color.textColor.name))
                        }
                    }

                    Section(
                        header:
                            Text(String(localized: "config-premium-plan"))
                            .foregroundStyle(Color(.appMainText))
                    ) {
                        Button {
                            viewState.subscriptionButtonTapped()
                        } label: {
                            Text(String(localized: "config-about-premium-plan"))
                                .foregroundColor(Color(R.color.textColor.name))
                        }
                    }

                    Section(
                        header:
                            Text("お問い合わせ")
                            .foregroundColor(Color(R.color.textColor.name))
                    ) {
                        NavigationLink(destination: ContactView(viewState: ContactViewState())) {
                            Text("お問い合わせ")
                                .foregroundColor(Color(R.color.textColor.name))
                        }
                    }

                    Section(
                        header:
                            Text("開発者情報")
                            .foregroundColor(Color(R.color.textColor.name))
                    ) {
                        Button(action: {
                            viewState.openUrlString(string: OfficialDiscordUrlString)
                        }) {
                            Text(String(localized: "config-official-discord"))
                                .foregroundColor(Color(R.color.textColor.name))
                        }

                        Button(action: {
                            viewState.openUrlString(string: OfficialTwitterUrlString)
                        }) {
                            Text(String(localized: "config-official-twitter"))
                                .foregroundColor(Color(R.color.textColor.name))
                        }
                    }

                    Section(
                        header:
                            Text(String(localized: "config-application-info"))
                            .foregroundColor(Color(R.color.textColor.name))
                    ) {
                        // バージョン情報
                        HStack {
                            Text(String(localized: "config-version-info"))
                                .foregroundColor(Color(R.color.textColor.name))
                            Spacer()
                            Text(viewState.versionString)
                                .foregroundColor(Color(R.color.textColor.name))
                        }

                        // ライセンス
                        NavigationLink {
                            LicenceView(viewState: LicenceViewState())
                        } label: {
                            Text(String(localized: "config-license"))
                        }

                        // その他
                        Button {
                            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            UIApplication.shared.open(settingsUrl, completionHandler: nil)
                        } label: {
                            Text(String(localized: "config-other-app-setting"))
                                .foregroundColor(Color(R.color.textColor.name))
                        }
                    }

                    Section(
                        header:
                            Text(String(localized: "config-reset"))
                            .foregroundStyle(Color(.appMainText))
                    ) {
                        Button(action: {
                            viewState.resetButtonTapped()
                        }) {
                            Text(String(localized: "config-reset"))
                                .foregroundColor(Color(R.color.textColor.name))
                        }
                        .alert(isPresented: $viewState.showingResetAlert) {
                            Alert(
                                title: Text(String(localized: "config-reset")),
                                message: Text(String(localized: "config-are-you-sure-you-want-to-reset-the-app")),
                                primaryButton: .default(Text(String(localized: "common-cancel"))) {
                                    // ResetCancel
                                }, secondaryButton: .destructive(Text(String(localized: "common-reset"))) {
                                    viewState.withdraw()
                                })
                        }
                    }

                    // 広告とリセットせるが被ってしまうのでパディング追加のため
                    // もっと良い方法があれば修正したい
                    Section("") {}
                }
                .listStyle(GroupedListStyle())
                .background(Color(.appBackground))
                .scrollContentBackground(.hidden)

                if viewState.isShowingADs {
                    AdmobBannerView(adUnitID: Variables.admobConfigUnitID)
                }
            }
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(.appMain), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .navigationBarItems(
                leading:
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                            .padding(.bottom, 4)
                            .foregroundStyle(Color.white)
                    }
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "config-config"))
                        .foregroundStyle(Color.white)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .fullScreenCover(isPresented: $viewState.showingSubscriptionSheet, content: {
            SubscriptionView(viewState: SubscriptionViewState())
        })
        .alert(isPresented: $viewState.showingAlert) {
            Alert(title: Text(""), message: Text(viewState.alertMessage), dismissButton: .default(Text(String(localized: "common-close"))))
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(viewState: ConfigViewState())
    }
}
