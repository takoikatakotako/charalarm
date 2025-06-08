import SwiftUI

struct MenuItem: View {
    var imageName: String

    var body: some View {
        Group {
            Image(imageName)
                .resizable()
                .frame(width: 40, height: 40)
        }.accentColor(.white)
            .frame(width: 60, height: 60)
            .background(Color.black)
            .cornerRadius(30)
            .shadow(color: .black, radius: 4, x: 4, y: 4)
            .opacity(0.9)
    }
}

struct MenuItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MenuItem(imageName: "profile-call")
            MenuItem(imageName: "profile-check")

        }.previewLayout(.fixed(width: 60, height: 60))
    }
}
