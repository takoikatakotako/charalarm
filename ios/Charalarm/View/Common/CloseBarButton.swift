import SwiftUI

struct CloseBarButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(.commonIconClose)
                .renderingMode(.template)
                .foregroundStyle(Color(.charalarmDefaultGray))
        }
    }
}

#Preview {
    CloseBarButton(action: {})
}
