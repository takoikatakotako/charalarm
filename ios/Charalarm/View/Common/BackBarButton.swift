import SwiftUI

struct BackBarButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(R.image.commonBackIcon.name)
                .renderingMode(.template)
                .foregroundStyle(Color(R.color.charalarmDefaultGray.name))
        }
    }
}

#Preview {
    BackBarButton(action: {})
}
