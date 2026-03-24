import SwiftUI
import GoogleMobileAds

struct AlarmListView: View {
    @Environment(\.dismiss) private var dismiss

    @State var viewState: AlarmListViewState = AlarmListViewState()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ZStack(alignment: .center) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewState.alarms) { alarm in
                                Button(action: {
                                    viewState.editAlarm(alarm: alarm)
                                }) {
                                    AlarmListRow(delegate: self, alarm: alarm)
                                }
                            }
                        }
                    }

                    if viewState.showingIndicator {
                        CharalarmActivityIndicator()
                    }
                }

                if viewState.isShowingADs {
                    AdmobBannerView(adUnitID: Variables.admobAlarmListUnitID)
                }
            }
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
            .navigationBarBackButtonHidden(true)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseBarButton {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewState.addAlarmButtonTapped()
                    }) {
                        Image(R.image.alarmAddIcon.name)
                            .renderingMode(.template)
                            .foregroundStyle(Color(R.color.charalarmDefaultGreen.name))
                    }
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
