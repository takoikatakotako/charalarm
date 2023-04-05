import SwiftUI
import GoogleMobileAds

struct AlarmListView: View {
    @EnvironmentObject var appState: CharalarmAppState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @StateObject var viewState: AlarmListViewState = AlarmListViewState()

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ZStack(alignment: .center) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewState.alarms) { alarm in
                                Button(action: {
                                    viewState.editAlarm(alarm: alarm)
                                }){
                                    AlarmListRow(delegate: self, alarm: alarm)
                                }
                            }
                        }
                    }
                    
                    if viewState.showingIndicator {
                        CharalarmActivityIndicator()
                    }
                }

                AdmobBannerView(adUnitID: ADMOB_ALARM_LIST_UNIT_ID)
            }
            .onAppear {
                viewState.fetchAlarms()
            }
            .alert(item: $viewState.alert) { item in
                switch item {
                case .ad:
                    return Alert(title: Text(""), message: Text("動画見てください！"), primaryButton: .default(Text("aaa"), action: {
                        print("Hello")
                    }), secondaryButton: .cancel())
                case let .error(_, message):
                    return Alert(title: Text(""), message: Text(message), dismissButton: .default(Text(R.string.localizable.commonClose())))
                }
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
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                leading: CloseBarButton() {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing:
                    Button(action: {
                        viewState.addAlarmButtonTapped()
                    }) {
                        Image(R.image.alarmAddIcon.name)
                            .renderingMode(.template)
                            .foregroundColor(Color(R.color.charalarmDefaultGreen.name))
                    }
            )
        }
    }
}

extension AlarmListView: AlarmListRowDelegate {
    func updateAlarmEnable(alarmId: UUID, isEnable: Bool) {
        viewState.updateAlarmEnable(alarmId: alarmId, isEnable: isEnable)
    }
}


struct AlarmListView_Previews: PreviewProvider {
    static var previews: some View {
        AlarmListView()
    }
}
