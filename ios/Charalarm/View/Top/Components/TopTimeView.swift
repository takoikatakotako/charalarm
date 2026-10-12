import SwiftUI

struct TopTimeView: View {
    var body: some View {
        // 時:分 を出すので、分が変わるときだけ描き直す
        TimelineView(.everyMinute) { context in
            Text(getTime(date: context.date))
                .foregroundStyle(Color.white)
                .font(Font.system(size: 56).bold())
                .padding(.top, 12)
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
