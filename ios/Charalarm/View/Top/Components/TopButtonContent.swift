import SwiftUI

struct TopButtonContent: View {
    let imageName: String
    var body: some View {
        Group {
            Image(imageName)
                .foregroundStyle(.white)
                .padding(8)
        }
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

#Preview {
    TopButtonContent(imageName: "top-news")
}
