import SwiftUI

/// 曜日のボタン。オンなら緑で塗る
struct AlarmDetailWeekdayButton: View {
    @Binding var enable: Bool
    let title: String

    var body: some View {
        Button {
            enable.toggle()
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(enable ? Color.white : Color.primary)
                .frame(width: 38, height: 38)
                .background(enable ? Color.brand : Color(.tertiarySystemFill), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(enable ? .isSelected : [])
    }
}

#Preview {
    HStack {
        AlarmDetailWeekdayButton(enable: .constant(true), title: "月")
        AlarmDetailWeekdayButton(enable: .constant(false), title: "火")
    }
}
