import SwiftUI

struct CharalarmActivityIndicator: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
            .scaleEffect(1.5)
            .padding(12)
            .background(Color.gray.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
