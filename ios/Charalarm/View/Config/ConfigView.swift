import SwiftUI

struct ConfigView: View {
    #if DEBUG
    private static let debugConversationCharaID = "jp.zunko.zundamon"
    #endif

    @State var viewState: ConfigViewState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "config-user-info")) {
                    NavigationLink(String(localized: "config-user-info")) {
                        UserInfoView(viewState: UserInfoViewState())
                    }
                }

                Section {
                    NavigationLink(String(localized: "config-background")) {
                        BackgroundSelectionView()
                    }
                }

                Section {
                    Toggle(String(localized: "config-tap-voice-in-silent-mode"), isOn: $viewState.tapVoiceInSilentMode)
                } header: {
                    Text(String(localized: "config-sound"))
                } footer: {
                    Text(String(localized: "config-tap-voice-in-silent-mode-footer"))
                }

                Section {
                    Picker(String(localized: "config-conversation-language"), selection: $viewState.conversationLanguage) {
                        ForEach(ConversationLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    Toggle(String(localized: "config-use-calendar"), isOn: Binding(
                        get: { viewState.useCalendarInConversation },
                        set: { viewState.setUseCalendarInConversation($0) }
                    ))
                    NavigationLink(String(localized: "calendar-selection-title")) {
                        CalendarSelectionView()
                    }
                    Toggle(String(localized: "config-mention-schedule-on-call"), isOn: Binding(
                        get: { viewState.mentionScheduleOnCall },
                        set: { viewState.setMentionScheduleOnCall($0) }
                    ))
                } header: {
                    Text(String(localized: "config-conversation"))
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "config-conversation-language-footer"))
                        Text(String(localized: "config-use-calendar-footer"))
                        Text(String(localized: "config-mention-schedule-on-call-footer"))
                    }
                }

                Section(String(localized: "config-premium-plan")) {
                    Button(String(localized: "config-about-premium-plan")) {
                        viewState.subscriptionButtonTapped()
                    }
                }

                Section(String(localized: "config-contact")) {
                    NavigationLink(String(localized: "config-contact")) {
                        ContactView(viewState: ContactViewState())
                    }
                }

                Section(String(localized: "config-developer-info")) {
                    if let url = URL(string: OfficialDiscordUrlString) {
                        Link(String(localized: "config-official-discord"), destination: url)
                    }
                    if let url = URL(string: OfficialTwitterUrlString) {
                        Link(String(localized: "config-official-twitter"), destination: url)
                    }

                    #if DEBUG
                    // ずんだもん会話の開発用動線（本番の動線はホーム画面の電話ボタン）
                    // Stub: 返答はオウム返し（キャラの会話の設定はサーバから取得する）
                    NavigationLink("[DEBUG] ずんだもんと通話 (Stub)") {
                        ConversationView(charaID: Self.debugConversationCharaID, textGenerationRepository: StubTextGenerationRepository())
                    }
                    #endif

                    // 同梱した時守しおりの VRM の表示確認（サーバに登録していなくても見られる）。
                    // TestFlight で試すため Release ビルドでも出す。5.0.0 のリリース前に外す
                    if let shioriModelURL = URL(string: "\(Variables.resourceEndpoint)/com.charalarm.shiori/shiori.vrm") {
                        NavigationLink("[試作] VRM プレビュー（時守しおり）") {
                            CharaVRMView(charaID: "com.charalarm.shiori", modelFileURL: shioriModelURL, framing: .full)
                        }
                    }
                }

                Section(String(localized: "config-application-info")) {
                    LabeledContent(String(localized: "config-version-info"), value: viewState.versionString)
                    NavigationLink(String(localized: "config-license")) {
                        LicenceView()
                    }
                    Button(String(localized: "config-other-app-setting")) {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            openURL(settingsUrl)
                        }
                    }
                }

                Section {
                    Button(String(localized: "config-reset"), role: .destructive) {
                        viewState.resetButtonTapped()
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
            }
            .bannerAd(isShowing: viewState.isShowingADs, adUnitID: Variables.admobConfigUnitID)
            .navigationTitle(String(localized: "config-config"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseBarButton {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $viewState.showingSubscriptionSheet) {
            SubscriptionView(viewState: SubscriptionViewState())
        }
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
