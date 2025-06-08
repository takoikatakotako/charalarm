import SwiftUI

struct CloseBarButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(R.image.commonIconClose.name)
                .renderingMode(.template)
                .foregroundColor(Color(R.color.charalarmDefaultGray.name))
        }
    }
}

struct CloseBarButton_Previews: PreviewProvider {
    static var previews: some View {
        CloseBarButton(action: {})
    }
}
