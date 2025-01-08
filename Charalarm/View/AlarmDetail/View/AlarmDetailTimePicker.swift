import SwiftUI

struct AlarmDetailTimePicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        HStack {
            Picker(selection: $hour, label: EmptyView()) {
                ForEach(0 ..< 24) {
                    Text(String(format: "%02d", $0))
                        .font(Font.system(size: 42).bold())
                }
            }.pickerStyle(WheelPickerStyle())
            .labelsHidden()
            .frame(width: 80, height: 200)
            .compositingGroup()
            .clipped()

            Text(":")
                .font(Font.system(size: 60).bold())
                .padding()

            Picker(selection: $minute, label: EmptyView()) {
                ForEach(0 ..< 60) {
                    Text(String(format: "%02d", $0))
                        .font(Font.system(size: 42).bold())
                }
            }.pickerStyle(WheelPickerStyle())
            .labelsHidden()
            .frame(width: 80, height: 200)
            .compositingGroup()
            .clipped()
        }
    }
}

struct AlarmDetailTimePicker_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var hour: Int = 3
        @State var minute: Int = 12
        var body: some View {
            AlarmDetailTimePicker(hour: $hour, minute: $minute)
        }
    }

    static var previews: some View {
        PreviewWrapper()
            .previewLayout(.sizeThatFits)
    }
}
