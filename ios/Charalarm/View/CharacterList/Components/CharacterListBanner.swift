import SwiftUI

/// キャラ一覧の下の「キャラのリクエスト」の案内
struct CharacterListBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(String(localized: "character-pr"))
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary, in: RoundedRectangle(cornerRadius: 4))
            Text(String(localized: "character-request"))
                .font(.footnote)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    CharacterListBanner()
        .padding()
        .background(Color(.systemGroupedBackground))
}
