import SwiftUI

/// チュートリアルの1画面の型（画像・見出し・文・下のボタン）。画面ごとの寄せ方や余白をそろえる
struct TutorialPage<Accessory: View, Footer: View>: View {
    let image: ImageResource
    var imageHeight: CGFloat = 280
    var title: String?
    let messages: [String]
    @ViewBuilder var accessory: () -> Accessory
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: imageHeight)
                .padding(.bottom, 32)

            VStack(spacing: 12) {
                if let title {
                    Text(title)
                        .font(.title3.bold())
                }
                ForEach(messages, id: \.self) { message in
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                accessory()
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            footer()
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension TutorialPage where Accessory == EmptyView {
    init(image: ImageResource, imageHeight: CGFloat = 280, title: String? = nil, messages: [String], @ViewBuilder footer: @escaping () -> Footer) {
        self.init(image: image, imageHeight: imageHeight, title: title, messages: messages, accessory: { EmptyView() }, footer: footer)
    }
}

#Preview {
    NavigationStack {
        TutorialPage(image: .zundamonNormal, title: "キャラームへようこそ！", messages: ["説明の文です。"]) {
            TutorialButtonContent(text: "次へ")
        }
    }
}
