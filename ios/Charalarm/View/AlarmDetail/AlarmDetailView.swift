import SwiftUI

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

    /// 時と分を時刻の選択につなぐ（日付とタイムゾーンは使わない）
    private var time: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: viewState.alarm.hour, minute: viewState.alarm.minute)) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                viewState.alarm.hour = components.hour ?? 0
                viewState.alarm.minute = components.minute ?? 0
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(String(localized: "alarm-time"), selection: time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    Button {
                        viewState.timeDirrerenceTapped()
                    } label: {
                        LabeledContent(String(localized: "alarm-time-difference"), value: viewState.timeDefferenceString)
                    }
                    .foregroundStyle(.primary)
                }

                Section(String(localized: "alarm-day-of-week")) {
                    AlarmDetailWeekdaySelector(alarm: $viewState.alarm)
                        .frame(maxWidth: .infinity)
                }

                Section(String(localized: "alarm-alarm-name")) {
                    TextField(String(localized: "alarm-please-enter-the-alarm-name"), text: $viewState.alarm.name)
                }

                Section(String(localized: "alarm-chara")) {
                    AlarmDetailCharaSelector(delegate: self, selectedChara: $viewState.selectedChara, charas: $viewState.characters)
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                }

                Section(String(localized: "alarm-voice")) {
                    Text(viewState.selectedCharaCall?.message ?? String(localized: "alarm-random"))
                }

                if viewState.type == .edit {
                    Section {
                        Button(String(localized: "alarm-delete-alarm"), role: .destructive) {
                            viewState.deleteAlarm()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .overlay {
                if viewState.showingIndicator {
                    CharalarmActivityIndicator()
                }
            }
            .onChange(of: viewState.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss {
                    dismiss()
                }
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
                    Button(String(localized: "common-save")) {
                        viewState.createOrEditAlarm()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("", isPresented: $viewState.showingAlert) {
                Button(String(localized: "common-close")) {}
            } message: {
                Text(viewState.alertMessage)
            }
            .sheet(item: $viewState.sheet) { item in
                switch item {
                case let .voiceList(chara):
                    AlarmDetailVoiceList(delegate: self, viewState: AlarmDetailVoiceListViewState(chara: chara))
                case .timeDifferenceList:
                    AlarmDetailTimeDifferenceSelector(timeDifference: $viewState.alarm.timeDifference)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension AlarmDetailView: AlarmDetailCharaSelectorDelegate {
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
