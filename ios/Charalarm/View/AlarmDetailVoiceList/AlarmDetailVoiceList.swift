import SwiftUI

struct AlarmDetailVoiceList: View {
    let delegate: AlarmDetailVoiceListDelegate
    @StateObject var viewState: AlarmDetailVoiceListState
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List {
                // ランダム用
                Button {
                    viewState.randomPlayAndSelecVoice()
                    delegate.selectCharaAndCall(chara: viewState.chara, charaCall: viewState.selectedCharaCall)
                } label: {
                    HStack {
                        Image(R.image.alarmVoicePlay.name)
                        Text("ランダム")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                // 指定して選択する
                ForEach(viewState.chara.calls, id: \.voiceFileURL) { charaCall in
                    Button {
                        viewState.playVoice(charaCall: charaCall)
                        delegate.selectCharaAndCall(chara: viewState.chara, charaCall: charaCall)
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack {
                            Image(R.image.alarmVoicePlay.name)
                            Text(charaCall.message)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                 }
            }
            .navigationBarTitle("\(viewState.chara.name)のボイス")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MockAlarmVoiceListViewDelegate: AlarmDetailVoiceListDelegate {
    func selectCharaAndCall(chara: Chara, charaCall: CharaCall?) {}
}
