import SwiftUI

struct SubscriptionCardView: View {
    let title: String
    let systemImageName: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)

            HStack {
                Spacer()
                Image(systemName: systemImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                Spacer()
            }
            .padding(.vertical, 24)
            .background(Color(R.color.charalarmDefaultGray.name))

            Text(description)
        }
        .padding()
        .background(Color.white)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray, lineWidth: 1)
                .shadow(color: Color.black, radius: 16, x: 0, y: 0)
        )
    }
}

struct SubscriptionCardView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionCardView(
            title: "特典１: アラーム数上限アップ",
            systemImageName: "calendar",
            description: "アラームを10個まで設定することができます"
        )
    }
}
