import SwiftUI
import UIKit
import SDWebImageSwiftUI

struct CharacterListRow: View {
    let chara: Chara
    var body: some View {
        HStack {
            WebImage(url: URL(string: chara.thumbnailUrlString))
                .resizable()
                .placeholder {
                    Image(R.image.characterPlaceholder.name)
                        .resizable()
            }
            .frame(width: 80, height: 80)
            .animation(.easeInOut, value: 0.5)
            .transition(.fade)
            .scaledToFill()

            VStack(alignment: .leading, spacing: 8) {
                Text(chara.name)
                    .font(Font.system(size: 18.0))

                ForEach(chara.profiles.prefix(2), id: \.hashValue) { profile in
                    Text("\(profile.title): \(profile.name)")
                                       .font(Font.system(size: 16.0))
                }
            }

            Spacer()
        }
    }
}

// struct CharacterListRow_Previews: PreviewProvider {
//    static var previews: some View {
//        CharacterListRow(character: Character(id: "com.charalarm.yui", name: "井上結衣"))
//            .previewLayout(.sizeThatFits)
//    }
// }
