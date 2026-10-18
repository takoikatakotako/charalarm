import SwiftUI

/// 前の画面に戻るボタン（ナビゲーションバーの左上）
struct BackBarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.backward")
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    BackBarButton(action: {})
}
