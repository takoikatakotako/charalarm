import SwiftUI

struct CallingView: View {
    @State var viewState: CallingViewState
    var body: some View {
        ZStack {
            CallBackground()

            VStack {
                CallerNameText(name: viewState.charaName ?? "Charalarm", status: String(localized: "calling-status"))
                    .padding(.top, 120)
                Spacer()
                CallActionButton(kind: .decline) {
                    viewState.endCall()
                }
                .padding(.bottom, 64)
            }
        }
    }
}

#Preview {
    CallingView(viewState: CallingViewState(charaID: nil, charaName: nil, callUUID: nil))
}

#Preview {
    CallingView(viewState: CallingViewState(charaID: nil, charaName: "井上結衣", callUUID: nil))
}
