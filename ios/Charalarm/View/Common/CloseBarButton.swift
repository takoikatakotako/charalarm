import SwiftUI

/// シートを閉じるボタン（ナビゲーションバーの左上）
struct CloseBarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .fontWeight(.semibold)
        }
        .accessibilityLabel(String(localized: "common-close"))
    }
}

#Preview {
    CloseBarButton(action: {})
}
