import SwiftUI

struct AlarmDetailVoiceList: View {
    let delegate: AlarmDetailVoiceListDelegate
    @State var viewState: AlarmDetailVoiceListState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
                        dismiss()
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
            .navigationTitle("\(viewState.chara.name)のボイス")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MockAlarmVoiceListViewDelegate: AlarmDetailVoiceListDelegate {
    func selectCharaAndCall(chara: Chara, charaCall: CharaCall?) {}
}
