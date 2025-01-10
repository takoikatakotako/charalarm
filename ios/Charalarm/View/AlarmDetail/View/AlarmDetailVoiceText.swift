import SwiftUI

struct AlarmDetailVoiceText: View {
    let fileMessage: String
    var body: some View {
        VStack(alignment: .leading) {
            Text("ボイス")
                .font(Font.system(size: 16).bold())
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            Text(fileMessage)
                .padding(.top, 8)
                .padding(.bottom, 16)
        }
    }
}

struct AlarmDetailVoiceText_Previews: PreviewProvider {
    static var previews: some View {
        AlarmDetailVoiceText(fileMessage: "あなたは死なないわ私が守るもの")
            .previewLayout(.sizeThatFits)
    }
}
