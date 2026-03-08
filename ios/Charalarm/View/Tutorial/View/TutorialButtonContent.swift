import SwiftUI

struct TutorialButtonContent: View {
    let text: String
    var body: some View {
        Text(text)
            .foregroundStyle(Color.white)
            .font(Font.system(size: 16).bold())
            .frame(height: 46)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color(R.color.charalarmDefaultGreen.name))
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    TutorialButtonContent(text: "プライバシーポリシーに同意する")
}
