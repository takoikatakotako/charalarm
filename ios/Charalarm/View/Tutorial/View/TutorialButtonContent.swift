import SwiftUI

struct TutorialButtonContent: View {
    let text: String
    var body: some View {
        Text(text)
            .foregroundColor(Color.white)
            .font(Font.system(size: 16).bold())
            .frame(height: 46)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color(R.color.charalarmDefaultGreen.name))
            .cornerRadius(24)
    }
}

struct TutorialButton_Previews: PreviewProvider {
    static var previews: some View {
        TutorialButtonContent(text: "プライバシーポリシーに同意する")
            .previewLayout(.sizeThatFits)
    }
}
