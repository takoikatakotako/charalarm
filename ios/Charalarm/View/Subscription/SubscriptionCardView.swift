import SwiftUI

/// プレミアムプランの特典の1枚
struct SubscriptionCardView: View {
    let title: String
    let systemImageName: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImageName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    SubscriptionCardView(
        title: "特典１: アラーム数上限アップ",
        systemImageName: "alarm.waves.left.and.right",
        description: "アラームを10個まで設定することができます"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
