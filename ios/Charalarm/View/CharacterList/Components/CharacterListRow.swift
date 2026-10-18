import SwiftUI
import SDWebImageSwiftUI

struct CharacterListRow: View {
    let chara: Chara

    var body: some View {
        HStack(spacing: 12) {
            WebImage(url: URL(string: chara.thumbnailUrlString)) { image in
                image.resizable()
            } placeholder: {
                Image(.characterPlaceholder)
                    .resizable()
            }
            .scaledToFill()
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(chara.name)
                    .font(.headline)
                ForEach(chara.profiles.prefix(2), id: \.hashValue) { profile in
                    Text("\(profile.title): \(profile.name)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
