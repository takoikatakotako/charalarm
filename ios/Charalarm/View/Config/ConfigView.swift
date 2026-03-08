import SwiftUI
import SDWebImageSwiftUI

struct ConfigView: View {
    @StateObject var viewState: ConfigViewState
    @Environment(\.dismiss) private var dismiss

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
                                .foregroundStyle(Color(R.color.textColor.name))
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
                                .foregroundStyle(Color(R.color.textColor.name))
                        }
                    }

                    Section(
                        header:
                            Text("お問い合わせ")
                            .foregroundStyle(Color(R.color.textColor.name))
                    ) {
                        NavigationLink(destination: ContactView(viewState: ContactViewState())) {
                            Text("お問い合わせ")
                                .foregroundStyle(Color(R.color.textColor.name))
                        }
                    }

                    Section(
                        header:
                            Text("開発者情報")
                            .foregroundStyle(Color(R.color.textColor.name))
                    ) {
                        Button(action: {
                            viewState.openUrlString(string: OfficialDiscordUrlString)
                        }) {
                            Text(String(localized: "config-official-discord"))
                                .foregroundStyle(Color(R.color.textColor.name))
                        }

                        Button(action: {
                            viewState.openUrlString(string: OfficialTwitterUrlString)
                        }) {
                            Text(String(localized: "config-official-twitter"))
                                .foregroundStyle(Color(R.color.textColor.name))
                        }
                    }

                    Section(
                        header:
                            Text(String(localized: "config-application-info"))
                            .foregroundStyle(Color(R.color.textColor.name))
                    ) {
                        // バージョン情報
                        HStack {
                            Text(String(localized: "config-version-info"))
                                .foregroundStyle(Color(R.color.textColor.name))
                            Spacer()
                            Text(viewState.versionString)
                                .foregroundStyle(Color(R.color.textColor.name))
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
                            UIApplication.shared.open(settingsUrl)
                        } label: {
                            Text(String(localized: "config-other-app-setting"))
                                .foregroundStyle(Color(R.color.textColor.name))
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
                                .foregroundStyle(Color(R.color.textColor.name))
                        }
                        .alert(String(localized: "config-reset"), isPresented: $viewState.showingResetAlert) {
                            Button(String(localized: "common-cancel"), role: .cancel) {}
                            Button(String(localized: "common-reset"), role: .destructive) {
                                viewState.withdraw()
                            }
                        } message: {
                            Text(String(localized: "config-are-you-sure-you-want-to-reset-the-app"))
                        }
                    }

                    // 広告とリセットせるが被ってしまうのでパディング追加のため
                    // もっと良い方法があれば修正したい
                    Section("") {}
                }
                .listStyle(.grouped)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                            .padding(.bottom, 4)
                            .foregroundStyle(Color.white)
                    }
                }
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
        .alert("", isPresented: $viewState.showingAlert) {
            Button(String(localized: "common-close")) {}
        } message: {
            Text(viewState.alertMessage)
        }
    }
}

#Preview {
    ConfigView(viewState: ConfigViewState())
}
