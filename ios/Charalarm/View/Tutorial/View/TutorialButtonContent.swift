import SwiftUI

/// チュートリアルの「次へ」などのボタンの中身。NavigationLink の見た目にも使うので、ButtonStyle ではなく中身にする
struct TutorialButtonContent: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.brand, in: Capsule())
    }
}

#Preview {
    TutorialButtonContent(text: "プライバシーポリシーに同意する")
        .padding()
}
