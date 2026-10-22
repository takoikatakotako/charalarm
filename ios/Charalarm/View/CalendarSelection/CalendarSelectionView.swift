import SwiftUI

/// 予定を読むカレンダーを選ぶ。設定画面と「今日の予定」の画面から開く
struct CalendarSelectionView: View {
    @State private var groups: [CalendarGroup] = []
    @State private var isAuthorized = CalendarRepository().isAuthorized
    @Environment(\.openURL) private var openURL

    private let calendarRepository = CalendarRepository()

    var body: some View {
        Form {
            if isAuthorized {
                ForEach(groups) { group in
                    Section(group.title) {
                        ForEach(group.calendars) { calendar in
                            Toggle(isOn: Binding(
                                get: { calendar.isSelected },
                                set: { isSelected in
                                    calendarRepository.setCalendar(id: calendar.id, isSelected: isSelected)
                                    reload()
                                }
                            )) {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(calendar.color)
                                        .frame(width: 12, height: 12)
                                    Text(calendar.title)
                                }
                            }
                        }
                    }
                }
                Section {
                } footer: {
                    Text(String(localized: "calendar-selection-footer"))
                }
            } else {
                Section {
                    Button(String(localized: "calendar-selection-allow")) {
                        Task {
                            isAuthorized = await calendarRepository.requestAccess()
                            if isAuthorized {
                                reload()
                            } else if let url = URL(string: UIApplication.openSettingsURLString) {
                                // 一度断っていると許可のダイアログが出ないので、設定アプリを開く
                                openURL(url)
                            }
                        }
                    }
                } footer: {
                    Text(String(localized: "calendar-selection-not-authorized"))
                }
            }
        }
        .navigationTitle(String(localized: "calendar-selection-title"))
        .onAppear {
            reload()
        }
    }

    private func reload() {
        isAuthorized = calendarRepository.isAuthorized
        groups = calendarRepository.calendarGroups()
    }
}

#Preview {
    NavigationStack {
        CalendarSelectionView()
    }
}
