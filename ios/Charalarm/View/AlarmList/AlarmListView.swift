import SwiftUI

struct AlarmListView: View {
    @Environment(\.dismiss) private var dismiss

    @State var viewState: AlarmListViewState = AlarmListViewState()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewState.alarms) { alarm in
                        Button {
                            viewState.editAlarm(alarm: alarm)
                        } label: {
                            AlarmListRow(delegate: self, alarm: alarm)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .overlay {
                if viewState.showingIndicator {
                    CharalarmActivityIndicator()
                } else if viewState.alarms.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "alarm-list-empty-title"), systemImage: "alarm")
                    } description: {
                        Text(String(localized: "alarm-list-empty-description"))
                    } actions: {
                        Button(String(localized: "alarm-add-alarm")) {
                            viewState.addAlarmButtonTapped()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .bannerAd(isShowing: viewState.isShowingADs, adUnitID: Variables.admobAlarmListUnitID)
            .onAppear {
                viewState.onAppear()
            }
            .alert(
                viewState.alertMessage ?? "",
                isPresented: $viewState.showingAlert,
                presenting: viewState.alertMessage
            ) { _ in
                Button(String(localized: "common-close")) {}
            } message: { message in
                Text(message)
            }
            .sheet(item: $viewState.sheet, onDismiss: {
                viewState.fetchAlarms()
            }, content: { (item: AlarmListViewSheetItem) in
                switch item {
                case .alarmDetailForCreate:
                    AlarmDetailView(viewState: AlarmDetailViewState(alarm: viewState.createNewAlarm(), type: .create))
                case let .alarmDetailForEdit(alarm):
                    AlarmDetailView(viewState: AlarmDetailViewState(alarm: alarm, type: .edit))
                }
            })
            .navigationTitle(String(localized: "alarm-list-title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseBarButton {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewState.addAlarmButtonTapped()
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel(String(localized: "alarm-add-alarm"))
                }
            }
        }
    }
}

extension AlarmListView: AlarmListRowDelegate {
    func updateAlarmEnable(alarmId: UUID, isEnable: Bool) {
        viewState.updateAlarmEnable(alarmId: alarmId, isEnable: isEnable)
    }
}

#Preview {
    AlarmListView()
}
