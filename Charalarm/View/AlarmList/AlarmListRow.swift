import SwiftUI

protocol AlarmListRowDelegate {
    func updateAlarmEnable(alarmId: UUID, isEnable: Bool)
}

class AlarmListRowModel: ObservableObject {
    let alarmID: UUID?
    let delegate: AlarmListRowDelegate?
    @Published var enable: Bool {
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
    @ObservedObject var alarmListModel: AlarmListRowModel
    let alarm: Alarm

    init(delegate: AlarmListRowDelegate, alarm: Alarm) {
        self.alarm = alarm
        self.alarmListModel = AlarmListRowModel(alarmID: alarm.alarmID, enable: alarm.enable, delegate: delegate)
    }

    var backgroundColor: Color {
        return alarm.enable ? Color(R.color.alarmCardBackgroundGreen.name) : Color(R.color.charalarmDefaultGray.name)
    }

    var toggleThumbColor: Color {
        return alarm.enable ? Color(R.color.alarmCardBackgroundGreen.name) : Color(R.color.charalarmDefaultGray.name)
    }

    var dayOfWeeksString: String {
        var text = ""
        text += alarm.sunday ? "\(String(localized: "day-of-week-sunday")) " : ""
        text += alarm.monday ? "\(String(localized: "day-of-week-monday")) " : ""
        text += alarm.tuesday ? "\(String(localized: "day-of-week-tuesday")) " : ""
        text += alarm.wednesday ? "\(String(localized: "day-of-week-wednesday")) " : ""
        text += alarm.thursday ? "\(String(localized: "day-of-week-thursday")) " : ""
        text += alarm.friday ? "\(String(localized: "day-of-week-friday")) " : ""
        text += alarm.saturday ? "\(String(localized: "day-of-week-saturday")) " : ""
        return text
    }

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 8) {
                Text(alarm.name)
                    .font(Font.system(size: 20))
                    .frame(width: UIScreen.main.bounds.size.width - 32, alignment: .leading)
                    .lineLimit(1)

                Text("\(String(format: "%02d", alarm.hour)):\(String(format: "%02d", alarm.minute))")
                    .font(Font.system(size: 36).bold())
                Text(dayOfWeeksString)
                    .font(Font.system(size: 20))
            }
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(Color.white)
            .padding(.leading, 16)

            HStack {
                Spacer()
                Toggle(isOn: $alarmListModel.enable) {
                    Text("")
                }.labelsHidden()
                .toggleStyle(ColoredToggleStyle(label: "", onColor: Color.white, offColor: Color.white, thumbColor: toggleThumbColor))
                .padding()
            }
        }
        .frame(height: 140)
        .background(backgroundColor)
        .cornerRadius(16)
        .padding(8)
    }
}

// ref: https://stackoverflow.com/questions/56479674/set-toggle-color-in-swiftui
struct ColoredToggleStyle: ToggleStyle {
    var label = ""
    var onColor = Color(UIColor.green)
    var offColor = Color(UIColor.systemGray5)
    var thumbColor = Color.white

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            Text(label)
            Spacer()
            Button(action: { configuration.isOn.toggle() }) {
                RoundedRectangle(cornerRadius: 20, style: .circular)
                    .fill(configuration.isOn ? onColor : offColor)
                    .frame(width: 50, height: 29)
                    .overlay(
                        Circle()
                            .fill(thumbColor)
                            .shadow(radius: 1, x: 0, y: 1)
                            .padding(1.5)
                            .offset(x: configuration.isOn ? 10 : -10))
                    .animation(.easeInOut, value: 0.1)
            }
        }
        .font(.title)
        .padding(.horizontal)
    }
}

struct MockAlarmListRowDelegate: AlarmListRowDelegate {
    func updateAlarmEnable(alarmId: UUID, isEnable: Bool) {

    }
}

struct AlarmListRow_Previews: PreviewProvider {
    struct PreviewWrapper: View {
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

    static var previews: some View {
        Group {
            PreviewWrapper()
                .previewDevice(PreviewDevice(rawValue: "iPhone X"))
                .previewDisplayName("iPhone X")

            PreviewWrapper(name: "長い長いモーニングコール。長い長いモーニングコール。")
                .previewDevice(PreviewDevice(rawValue: "iPhone X"))
                .previewDisplayName("iPhone X")

            PreviewWrapper()
                .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
                .previewDisplayName("iPhone 8")
        }
    }
}
