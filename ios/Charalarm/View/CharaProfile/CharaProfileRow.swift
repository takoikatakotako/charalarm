import SwiftUI

/// キャラの紹介の1行（見出しと中身。URL があれば開ける）
struct CharaProfileRow: View {
    let title: String
    let text: String
    let url: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            if let url {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text(text)
                        Image(systemName: "arrow.up.right.square")
                            .font(.footnote)
                    }
                }
            } else {
                Text(text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    VStack {
        CharaProfileRow(title: "名前", text: "井上結衣", url: nil)
        CharaProfileRow(title: "イラスト", text: "さいもん", url: URL(string: "https://swiswiswift.com/"))
    }
}
