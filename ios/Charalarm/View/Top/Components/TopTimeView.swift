import SwiftUI

struct TopTimeView: View {
    var body: some View {
        // 時:分 を出すので、分が変わるときだけ描き直す
        TimelineView(.everyMinute) { context in
            Text(getTime(date: context.date))
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
        }
    }

    func getTime(date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return String(format: "%02d", hour) + ":" + String(format: "%02d", minute)
    }
}

#Preview {
    TopTimeView()
}
