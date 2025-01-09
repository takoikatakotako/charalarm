import SwiftUI

struct CallingView: View {
    @StateObject var viewState: CallingViewState
    var body: some View {
        ZStack {
            Color.gray
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                Text("Calling...")
                    .font(Font.system(size: 40).bold())
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    viewState.endCall()
                }) {
                    Image(systemName: "phone.fill.arrow.down.left")
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(width: 40, height: 40)
                }
                .frame(width: 80, height: 80)
                .background(Color(R.color.callRed.name))
                .cornerRadius(40)
                .padding(.bottom, 48)
            }
            .ignoresSafeArea(.all)
        }
    }
}

struct CallingView_Previews: PreviewProvider {
    static var previews: some View {
        CallingView(viewState: CallingViewState(charaID: nil, charaName: nil, callUUID: nil))

        CallingView(viewState: CallingViewState(charaID: nil, charaName: "井上結衣", callUUID: nil))
    }
}
