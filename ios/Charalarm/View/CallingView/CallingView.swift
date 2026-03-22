import SwiftUI

struct CallingView: View {
    @State var viewState: CallingViewState
    var body: some View {
        ZStack {
            Color.gray
                .ignoresSafeArea()

            VStack {
                Spacer()

                Text("Calling...")
                    .font(Font.system(size: 40).bold())
                    .foregroundStyle(.white)

                Spacer()

                Button(action: {
                    viewState.endCall()
                }) {
                    Image(systemName: "phone.fill.arrow.down.left")
                        .resizable()
                        .foregroundStyle(Color.white)
                        .frame(width: 40, height: 40)
                }
                .frame(width: 80, height: 80)
                .background(Color(R.color.callRed.name))
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .padding(.bottom, 48)
            }
            .ignoresSafeArea(.all)
        }
    }
}

#Preview {
    CallingView(viewState: CallingViewState(charaID: nil, charaName: nil, callUUID: nil))
}

#Preview {
    CallingView(viewState: CallingViewState(charaID: nil, charaName: "井上結衣", callUUID: nil))
}
