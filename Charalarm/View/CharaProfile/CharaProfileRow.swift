import SwiftUI

struct CharaProfileRow: View {
    let title: String
    let text: String
    let url: URL?
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(Font.headline)
                    .foregroundColor(Color.gray)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                Text(text)
                    .foregroundColor(Color.gray)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
            }

            if let url = url {
                Button(action: {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }, label: {
                    Image(R.image.profileOpenUrl.name)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color(R.color.charalarmDefaultGray.name))
                        .frame(width: 24, height: 24, alignment: .center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 16)
                })
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ProfileRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CharaProfileRow(title: "名前", text: "井上結衣", url: URL(string: "https://swiswiswift.com/")!)
                .previewLayout(.sizeThatFits)

            CharaProfileRow(title: "プロフィール", text: "長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。長い長いプロフィール。", url: nil)
                .previewLayout(.sizeThatFits)
        }
    }
}
