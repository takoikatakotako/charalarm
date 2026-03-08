import SwiftUI

struct CloseBarButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(R.image.commonIconClose.name)
                .renderingMode(.template)
                .foregroundStyle(Color(R.color.charalarmDefaultGray.name))
        }
    }
}

#Preview {
    CloseBarButton(action: {})
}
