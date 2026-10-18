import SwiftUI

struct AlarmDetailWeekdaySelector: View {
    @Binding var alarm: Alarm
    var body: some View {
        HStack {
            AlarmDetailWeekdayButton(enable: $alarm.sunday, title: String(localized: "day-of-week-sunday"))
            AlarmDetailWeekdayButton(enable: $alarm.monday, title: String(localized: "day-of-week-monday"))
            AlarmDetailWeekdayButton(enable: $alarm.tuesday, title: String(localized: "day-of-week-tuesday"))
            AlarmDetailWeekdayButton(enable: $alarm.wednesday, title: String(localized: "day-of-week-wednesday"))
            AlarmDetailWeekdayButton(enable: $alarm.thursday, title: String(localized: "day-of-week-thursday"))
            AlarmDetailWeekdayButton(enable: $alarm.friday, title: String(localized: "day-of-week-friday"))
            AlarmDetailWeekdayButton(enable: $alarm.saturday, title: String(localized: "day-of-week-saturday"))
        }
    }
}
