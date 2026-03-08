import SwiftUI

struct AlarmDetailWeekdayButton: View {
    @Binding var enable: Bool
    let title: String

    var body: some View {
        Button(action: {
            enable.toggle()
        }) {
            Text(title)
                .font(Font.system(size: 16).bold())
                .foregroundStyle(enable ? Color.white : Color.black)
                .frame(width: 40, height: 40)
                .background(enable ? Color(R.color.alarmCardBackgroundGreen.name) : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(R.color.alarmCardBackgroundGreen.name), lineWidth: 2)
                )
        }
    }
}

#Preview {
    AlarmDetailWeekdayButton(enable: .constant(true), title: String(localized: "day-of-week-monday"))
}
