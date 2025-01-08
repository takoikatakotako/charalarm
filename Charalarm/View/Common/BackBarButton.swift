import SwiftUI

struct BackBarButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(R.image.commonBackIcon.name)
                .renderingMode(.template)
                .foregroundColor(Color(R.color.charalarmDefaultGray.name))
        }
    }
}

struct BackBarButton_Previews: PreviewProvider {
    static var previews: some View {
        BackBarButton(action: {})
    }
}
