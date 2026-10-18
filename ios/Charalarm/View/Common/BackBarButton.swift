import SwiftUI

struct BackBarButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(.commonBackIcon)
                .renderingMode(.template)
                .foregroundStyle(Color(.charalarmDefaultGray))
        }
    }
}

#Preview {
    BackBarButton(action: {})
}
