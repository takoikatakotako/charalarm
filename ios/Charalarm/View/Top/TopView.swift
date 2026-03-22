import SwiftUI
import AVFoundation
import CallKit
import PushKit
import AVKit
import GoogleMobileAds

struct TopView: View {
    @State var viewState = TopViewState()
    @StateObject var adDelegate = AdmobRewardedHandler()

    var body: some View {
        ZStack {
            Image(R.image.background.name)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)

            VStack(spacing: 0) {
                Image(uiImage: viewState.charaImage)
                    .resizable()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .scaledToFit()
                    .padding(.top, 60)
            }

            Button(action: {
                viewState.tapped()
            }) {
                Text("")
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()

                        Button(action: {
                            viewState.newsButtonTapped()
                        }) {
                            Image(R.image.topNews.name)
                        }
                        .padding()
                        .padding(.top, 8)
                    }
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.setChara)) { notification in
            let charaID: String? = notification.userInfo?[NSNotification.setCharaUserInfoKeyCharaID] as? String
            viewState.updateChara(charaID: charaID)
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
        .sheet(item: $viewState.sheet) {
            // On Dissmiss
        } content: { item in
            switch item {
            case .newsList:
                NewsListView()
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
