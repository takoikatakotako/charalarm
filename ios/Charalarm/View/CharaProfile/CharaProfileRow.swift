import SwiftUI

struct CharaProfileRow: View {
    @Environment(\.openURL) private var openURL
    let title: String
    let text: String
    let url: URL?
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(Font.headline)
                    .foregroundStyle(Color.gray)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                Text(text)
                    .foregroundStyle(Color.gray)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
            }

            if let url = url {
                Button(action: {
                    openURL(url)
                }, label: {
                    Image(R.image.profileOpenUrl.name)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color(R.color.charalarmDefaultGray.name))
                        .frame(width: 24, height: 24, alignment: .center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 16)
                })
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    CharaProfileRow(title: "名前", text: "井上結衣", url: URL(string: "https://swiswiswift.com/")!)
}
