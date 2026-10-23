import SwiftUI
import GoogleMobileAds

struct TopView: View {
    @State var viewState = TopViewState()
    @State private var adDelegate = AdmobRewardedHandler()
    @AppStorage(TopBackground.defaultsKey) private var selectedBackground = TopBackground.washitsu.rawValue

    var body: some View {
        ZStack {
            Image(TopBackground.from(selectedBackground).image)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)

            VStack(spacing: 0) {
                if let vrmChara = viewState.vrmChara {
                    CharaVRMView(charaID: vrmChara.charaID, modelFileURL: vrmChara.modelFileURL, framing: .bust)
                        .id(vrmChara.charaID)
                        .padding(.top, 60)
                } else {
                    Image(uiImage: viewState.charaImage)
                        .resizable()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .scaledToFit()
                        .padding(.top, 60)
                }
            }

            Button(action: {
                viewState.tapped()
            }) {
                Text("")
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    // 何も描いていないところもタップできるようにする
                    .contentShape(Rectangle())
            }

            VStack(spacing: 0) {
                // 上: 今日の予定・お知らせ
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // キャラが今日の予定を読み上げる
                            Button {
                                Task {
                                    await viewState.todayScheduleButtonTapped()
                                }
                            } label: {
                                TopPillLabel(systemImageName: "calendar", text: String(localized: "top-today-schedule"))
                            }
                            .disabled(viewState.isPreparingCall)
                        }
                    }

                    Button {
                        viewState.newsButtonTapped()
                    } label: {
                        Image(systemName: "bell.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.black.opacity(0.3), in: Circle())
                            // まだ読んでいないお知らせがあれば点を付ける
                            .overlay(alignment: .topTrailing) {
                                if viewState.hasUnreadNews {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .offset(x: -4, y: 4)
                                }
                            }
                    }
                    .accessibilityLabel(String(localized: "top-news"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
                .padding(.bottom, 24)
                .background(LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))

                Spacer()

                // 下: タップで流したセリフと、キャラ・アラーム・電話・設定
                VStack(spacing: 12) {
                    if let tapLineText = viewState.tapLinePlayer.text {
                        Text(tapLineText)
                            .font(.callout)
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 16)
                            // キャラをタップするじゃまをしない
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }

                    HStack(spacing: 0) {
                        Button {
                            viewState.characterListButtonTapped()
                        } label: {
                            TopButtonContent(systemImageName: "person.2.fill", title: String(localized: "top-chara"))
                        }

                        Button {
                            viewState.alarmButtonTapped()
                        } label: {
                            TopButtonContent(systemImageName: "alarm.fill", title: String(localized: "top-alarm"))
                        }

                        Button {
                            Task {
                                await viewState.callButtonTapped()
                            }
                        } label: {
                            TopButtonContent(systemImageName: "phone.fill", title: String(localized: "top-call"))
                        }
                        .disabled(viewState.isPreparingCall)

                        Button {
                            viewState.configButtonTapped()
                        } label: {
                            TopButtonContent(systemImageName: "gearshape.fill", title: String(localized: "top-config"))
                        }
                    }
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .environment(\.colorScheme, .dark)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 34)
            }
        }
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .animation(.easeInOut(duration: 0.2), value: viewState.tapLinePlayer.text)
        .task {
            for await notification in NotificationCenter.default.notifications(named: NSNotification.setChara) {
                let charaID: String? = notification.userInfo?[NSNotification.setCharaUserInfoKeyCharaID] as? String
                viewState.updateChara(charaID: charaID)
            }
        }
        .onAppear {
            viewState.onAppear()
            adDelegate.load()
        }
        .alert(
            viewState.alert?.message ?? "",
            isPresented: $viewState.showingAlert,
            presenting: viewState.alert
        ) { _ in
            Button(String(localized: "common-close")) {}
        } message: { item in
            Text(item.message)
        }
        .fullScreenCover(item: $viewState.conversationChara) { chara in
            ConversationView(charaID: chara.charaID, topic: chara.topic)
        }
        .sheet(item: $viewState.sheet) {
            viewState.checkUnreadNews()
        } content: { item in
            switch item {
            case .news:
                NewsHubView(
                    trendNewsRepository: DummyTrendNewsRepository(),
                    initialTab: viewState.hasUnreadNews ? .news : .trend
                ) { news in
                    Task {
                        await viewState.readTrendNews(news)
                    }
                }
            case .characterList:
                CharaListView(viewState: CharacterListViewState())
            case .alarmList:
                AlarmListView()
            case .config:
                ConfigView(viewState: ConfigViewState())
            }
        }
    }
}

#Preview {
    TopView()
}
