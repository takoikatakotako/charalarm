import SwiftUI

protocol AlarmListRowDelegate {
    func updateAlarmEnable(alarmId: UUID, isEnable: Bool)
}

@MainActor @Observable final class AlarmListRowModel {
    let alarmID: UUID?
    let delegate: AlarmListRowDelegate?
    var enable: Bool {
        didSet {
            guard let alarmId = alarmID else {
                return
            }
            self.delegate?.updateAlarmEnable(alarmId: alarmId, isEnable: enable)
        }
    }

    init (alarmID: UUID, enable: Bool, delegate: AlarmListRowDelegate) {
        self.enable = enable
        self.alarmID = alarmID
        self.delegate = delegate
    }
}

struct AlarmListRow: View {
    @Bindable var alarmListModel: AlarmListRowModel
    let alarm: Alarm

    init(delegate: AlarmListRowDelegate, alarm: Alarm) {
        self.alarm = alarm
        self.alarmListModel = AlarmListRowModel(alarmID: alarm.alarmID, enable: alarm.enable, delegate: delegate)
    }

    var dayOfWeeksString: String {
        let days: [(Bool, String)] = [
            (alarm.sunday, String(localized: "day-of-week-sunday")),
            (alarm.monday, String(localized: "day-of-week-monday")),
            (alarm.tuesday, String(localized: "day-of-week-tuesday")),
            (alarm.wednesday, String(localized: "day-of-week-wednesday")),
            (alarm.thursday, String(localized: "day-of-week-thursday")),
            (alarm.friday, String(localized: "day-of-week-friday")),
            (alarm.saturday, String(localized: "day-of-week-saturday"))
        ]
        return days.filter(\.0).map(\.1).joined(separator: " ")
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(String(format: "%02d:%02d", alarm.hour, alarm.minute))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(dayOfWeeksString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .opacity(alarmListModel.enable ? 1 : 0.45)

            Spacer()

            Toggle(isOn: $alarmListModel.enable) {
                Text(alarm.name)
            }
            .labelsHidden()
            .tint(.brand)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MockAlarmListRowDelegate: AlarmListRowDelegate {
    func updateAlarmEnable(alarmId: UUID, isEnable: Bool) {

    }
}

private struct AlarmListRowPreviewWrapper: View {
    let alarm: Alarm
    init(enable: Bool = true, name: String = "モーニングコール", hour: Int = 9, minute: Int = 30) {
        self.alarm = Alarm(
            alarmID: UUID(),
            type: .IOS_VOIP_PUSH_NOTIFICATION,
            enable: true,
            name: "xxxx",
            hour: 8,
            minute: 30,
            timeDifference: 0,
            charaName: "xxxx",
            charaID: "xxxx",
            voiceFileName: "ssssss",
            sunday: true,
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: true
        )
    }

    var body: some View {
        AlarmListRow(delegate: MockAlarmListRowDelegate(), alarm: alarm)
    }
}

#Preview {
    AlarmListRowPreviewWrapper()
}
