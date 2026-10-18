import SwiftUI

/// トップの下に並べるボタンの中身（アイコンと短い名前）
struct TopButtonContent: View {
    let systemImageName: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImageName)
                .font(.system(size: 22, weight: .semibold))
                .frame(height: 28)
            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

#Preview {
    HStack {
        TopButtonContent(systemImageName: "person.2.fill", title: "キャラ")
        TopButtonContent(systemImageName: "phone.fill", title: "電話")
    }
    .padding()
    .background(.gray)
}
