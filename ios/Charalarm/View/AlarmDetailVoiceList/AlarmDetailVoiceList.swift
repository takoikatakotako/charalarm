import SwiftUI

struct AlarmDetailVoiceList: View {
    let delegate: AlarmDetailVoiceListDelegate
    @State var viewState: AlarmDetailVoiceListViewState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // ランダム用
                Button {
                    viewState.randomPlayAndSelecVoice()
                    delegate.selectCharaAndCall(chara: viewState.chara, charaCall: viewState.selectedCharaCall)
                } label: {
                    Label(String(localized: "alarm-random"), systemImage: "shuffle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // 指定して選択する
                ForEach(viewState.chara.calls, id: \.voiceFileURL) { charaCall in
                    Button {
                        viewState.playVoice(charaCall: charaCall)
                        delegate.selectCharaAndCall(chara: viewState.chara, charaCall: charaCall)
                        dismiss()
                    } label: {
                        Label {
                            Text(charaCall.message)
                        } icon: {
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(.brand)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(String(format: String(localized: "alarm-voice-list-title"), viewState.chara.name))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MockAlarmVoiceListViewDelegate: AlarmDetailVoiceListDelegate {
    func selectCharaAndCall(chara: Chara, charaCall: CharaCall?) {}
}
