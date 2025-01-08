import SwiftUI

protocol AlarmDetailDeleteAlarmDelegate {
    func deleteAlarm(alarmId: UUID)
}

struct AlarmDetailDeleteAlarmButton: View {
    let delegate: AlarmDetailDeleteAlarmDelegate
    let alarmId: UUID
    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                delegate.deleteAlarm(alarmId: alarmId)
            }) {
                Text(String(localized: "alarm-delete-alarm"))
                    .foregroundColor(Color.white)
                    .font(Font.system(size: 16).bold())
                    .frame(height: 46)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(Color(R.color.charalarmDefaultPink.name))
                    .cornerRadius(28)
                    .padding(.horizontal, 24)
            }
        }
    }
}

struct AlarmDetailDeleteAlarmButton_Previews: PreviewProvider {

    struct PreviewWrapper: View, AlarmDetailDeleteAlarmDelegate {
        var body: some View {
            AlarmDetailDeleteAlarmButton(delegate: self, alarmId: UUID())
        }
        func deleteAlarm(alarmId: UUID) {}
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
