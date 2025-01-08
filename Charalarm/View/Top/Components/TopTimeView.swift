import SwiftUI

struct TopTimeView: View {
    @State var currentDate = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(getTime())
            .foregroundColor(Color.white)
            .font(Font.system(size: 56).bold())
            .padding(.top, 12)
        .onReceive(timer) { input in
            self.currentDate = input
        }
    }

    func getTime() -> String {
        let calendar = Calendar(identifier: .gregorian)
        let hour = calendar.component(.hour, from: currentDate)
        let minute = calendar.component(.minute, from: currentDate)
        return String(format: "%02d", hour) + ":" + String(format: "%02d", minute)
    }

    func getDayAndDayOfWeek() -> String {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: currentDate)
        let day = calendar.component(.day, from: currentDate)
        return String(format: "%02d", month) + "/" + String(format: "%02d", day) + "(" + getDayOfWeek() + ")"
    }

    func getDayOfWeek() -> String {
        let calendar = Calendar(identifier: .gregorian)
        let component = calendar.component(.weekday, from: currentDate)
        let weekday = component - 1
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja")
        return String(formatter.weekdaySymbols[weekday].prefix(1))
    }
}

struct TopTimeView_Previews: PreviewProvider {
    static var previews: some View {
        TopTimeView()
            .previewLayout(.sizeThatFits)
    }
}
