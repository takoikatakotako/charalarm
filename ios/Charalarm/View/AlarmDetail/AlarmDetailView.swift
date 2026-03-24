import SwiftUI
import SDWebImageSwiftUI

struct AlarmDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewState: AlarmDetailViewState

    private var title: String {
        switch viewState.type {
        case .create:
            return String(localized: "alarm-add-alarm")
        case .edit:
            return String(localized: "alarm-edit-alarm")
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .center) {
                        AlarmDetailTimePickerTemp(hour: $viewState.alarm.hour, minute: $viewState.alarm.minute)

                        HStack {
                            Spacer()
                            Button {
                                viewState.timeDirrerenceTapped()
                            } label: {
                                Text(viewState.timeDefferenceString)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                        AlarmDetailWeekdaySelecter(alarm: $viewState.alarm)

                        VStack(alignment: .leading) {
                            TextField(String(localized: "alarm-please-enter-the-alarm-name"), text: $viewState.alarm.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)

                        AlarmDetailCharaSelecter(delegate: self, selectedChara: $viewState.selectedChara, charas: $viewState.characters)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)

                        AlarmDetailVoiceText(fileMessage: viewState.selectedCharaCall?.message ?? "ランダム")
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)

                        if viewState.type == .edit {
                            AlarmDetailDeleteAlarmButton(delegate: self, alarmId: viewState.alarm.alarmID)
                        }
                    }
                }

                if viewState.showingIndicator {
                    CharalarmActivityIndicator()
                }

            }
            .onReceive(viewState.dismissRequest) { _ in
                dismiss()
            }
            .onAppear {
                viewState.onAppear()
            }
            .onDisappear {
                viewState.onDisappear()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseBarButton {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewState.createOrEditAlarm()
                    }) {
                        Text(String(localized: "common-save"))
                            .foregroundStyle(Color(R.color.charalarmDefaultGreen.name))
                    }
                }
            }
            .alert("", isPresented: $viewState.showingAlert) {
                Button("閉じる") {}
            } message: {
                Text(viewState.alertMessage)
            }
            .sheet(item: $viewState.sheet) { item in
                switch item {
                case let .voiceList(chara):
                    AlarmDetailVoiceList(delegate: self, viewState: AlarmDetailVoiceListState(chara: chara))
                case .timeDeffarenceList:
                    AlarmDetailTimeDeffarenceSelecter(timeDeffarence: $viewState.alarm.timeDifference)
                }
            }
            .toolbar(.visible, for: .navigationBar)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension AlarmDetailView: AlarmDetailCharaSelecterDelegate {
    func setRandomChara() {
        viewState.setRandomChara()
    }

    func showVoiceList(chara: Chara) {
        viewState.showVoiceList(chara: chara)
    }
}

extension AlarmDetailView: AlarmDetailVoiceListDelegate {
    func selectCharaAndCall(chara: Chara, charaCall: CharaCall?) {
        viewState.setCharaAndCharaCall(chara: chara, charaCall: charaCall)
    }
}

extension AlarmDetailView: AlarmDetailDeleteAlarmDelegate {
    func deleteAlarm(alarmId: UUID) {
        viewState.deleteAlarm()
    }
}

// struct AlarmDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        AlarmDetailView(alarm: Alarm2(id: "2", hour: "1", minute: "3"))
//    }
// }
