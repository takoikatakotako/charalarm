import SwiftUI

struct RootView: View {
    @State var viewState: RootViewState

    var body: some View {
        ZStack {
            if viewState.type == .loading {
                Image(.charalarmLogo)
            } else if viewState.type == .maintenance {
                MaintenanceView()
            } else if viewState.type == .updateRequire {
                UpdateRequiredView()
            } else if viewState.type == .top {
                TopView()
            } else if viewState.type == .tutorial {
                TutorialHolderView()
            } else if viewState.type == .calling {
                CallingView(viewState: CallingViewState(charaID: viewState.charaID, charaName: viewState.charaName, callUUID: viewState.callUUID))
            } else if viewState.type == .conversation {
                ConversationView(charaID: viewState.charaID ?? "", mode: .callKit(callUUID: viewState.callUUID))
            } else if viewState.type == .error {
                ErrorView(viewState: ErrorViewState())
            }
        }
        .onAppear {
            viewState.onAppear()
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSNotification.doneTutorial) {
                viewState.doneTutorial()
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSNotification.didReset) {
                viewState.didReset()
            }
        }
        .task {
            let answeredCalls = NotificationCenter.default.notifications(named: NSNotification.answerCall)
            // 受け取る準備をする前に電話に出ていたら、ここで合わせる
            viewState.showAnsweredCallIfNeeded()
            for await _ in answeredCalls {
                viewState.showAnsweredCallIfNeeded()
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSNotification.endCall) {
                viewState.endCall()
            }
        }
    }
}

#Preview {
    RootView(viewState: RootViewState())
}
