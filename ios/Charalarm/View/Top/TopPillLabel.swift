import SwiftUI

/// トップの上に並べる小さなボタンの見た目（アイコンと短い文字）。
struct TopPillLabel: View {
    let systemImageName: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImageName)
            Text(text)
                .lineLimit(1)
        }
        .font(.footnote.bold())
        .foregroundStyle(Color.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 40)
        .background(.black.opacity(0.3), in: Capsule())
    }
}

#Preview {
    TopPillLabel(systemImageName: "calendar", text: "今日の予定")
}
