import SwiftUI
import AVFoundation
import CallKit
import PushKit
import AVKit
import GoogleMobileAds

struct TopView: View {
    @State var viewState = TopViewState()
    @State private var adDelegate = AdmobRewardedHandler()

    var body: some View {
        ZStack {
            Image(R.image.background.name)
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

            // タップで流したセリフの吹き出し（タップのじゃまをしない）
            if let tapLineText = viewState.tapLineText {
                VStack {
                    Text(tapLineText)
                        .font(.callout)
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 32)
                        .padding(.top, 150)
                    Spacer()
                }
                .allowsHitTesting(false)
                .transition(.opacity)
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
                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        // 会話とタップのセリフの言語
                        Menu {
                            Picker(String(localized: "config-conversation-language"), selection: $viewState.conversationLanguage) {
                                ForEach(ConversationLanguage.allCases) { language in
                                    Text(language.displayName).tag(language)
                                }
                            }
                        } label: {
                            TopPillLabel(systemImageName: "globe", text: viewState.conversationLanguage.displayName)
                        }

                        // キャラが今日の予定を読み上げる
                        Button(action: {
                            Task {
                                await viewState.todayScheduleButtonTapped()
                            }
                        }) {
                            TopPillLabel(systemImageName: "calendar", text: String(localized: "top-today-schedule"))
                        }
                        .disabled(viewState.isPreparingCall)

                        // 話題のニュース（キャラが紹介する）
                        Button(action: {
                            viewState.trendNewsButtonTapped()
                        }) {
                            TopPillLabel(systemImageName: "sparkles", text: String(localized: "top-trend-news"))
                        }
                        .disabled(viewState.isPreparingCall)

                        Spacer()

                        Button(action: {
                            viewState.newsButtonTapped()
                        }) {
                            Image(R.image.topNews.name)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .frame(height: 140)
                    .background(LinearGradient(gradient: Gradient(colors: [.gray, .clear]), startPoint: UnitPoint(x: 0.5, y: 0), endPoint: UnitPoint(x: 0.5, y: 1)))
                }

                Spacer()

                VStack(spacing: 8) {
                    TopTimeView()

                    HStack {
                        Spacer()
                        Button(action: {
                            viewState.characterListButtonTapped()
                        }) {
                            TopButtonContent(imageName: R.image.topPerson.name)
                        }

                        Spacer()

                        Button(action: {
                            viewState.alarmButtonTapped()
                        }) {
                            TopButtonContent(imageName: R.image.topAlarm.name)
                        }

                        Spacer()

                        Button(action: {
                            Task {
                                await viewState.callButtonTapped()
                            }
                        }) {
                            TopButtonContent(systemImageName: "phone.fill")
                        }
                        .disabled(viewState.isPreparingCall)

                        Spacer()

                        Button(action: {
                            viewState.configButtonTapped()
                        }) {
                            TopButtonContent(imageName: R.image.topConfig.name)
                        }

                        Spacer()
                    }
                    .padding(.bottom, 32)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.2)]), startPoint: UnitPoint(x: 0.5, y: 0.03), endPoint: UnitPoint(x: 0.5, y: 0)).opacity(0.9))
            }
        }
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .animation(.easeInOut(duration: 0.2), value: viewState.tapLineText)
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
            // On Dissmiss
        } content: { item in
            switch item {
            case .newsList:
                NewsListView()
            case .trendNews:
                TrendNewsView(repository: DummyTrendNewsRepository()) { news in
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
