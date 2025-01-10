import SwiftUI

struct TopButtonContent: View {
    let imageName: String
    var body: some View {
        Group {
            Image(imageName)
                .foregroundColor(.white)
                .padding(8)
        }
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

struct TopButton_Previews: PreviewProvider {
    static var previews: some View {
        TopButtonContent(imageName: "top-news")
            .previewLayout(.sizeThatFits)
    }
}
