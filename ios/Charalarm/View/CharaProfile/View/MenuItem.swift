import SwiftUI

struct MenuItem: View {
    var image: ImageResource

    var body: some View {
        Group {
            Image(image)
                .resizable()
                .frame(width: 40, height: 40)
        }.tint(.white)
            .frame(width: 60, height: 60)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: .black, radius: 4, x: 4, y: 4)
            .opacity(0.9)
    }
}

#Preview {
    MenuItem(image: .profileCall)
}
