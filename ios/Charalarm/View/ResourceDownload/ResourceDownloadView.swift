import SwiftUI

struct ResourceDownloadView: View {
    @State var viewState: ResourceDownloadViewState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            if !viewState.showDismissButton {
                ProgressView()
                    .controlSize(.large)
            }
            Text(viewState.mainMessage)
                .font(.headline)
            Text(viewState.progressMessage)
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Spacer()
            if viewState.showDismissButton {
                Button(String(localized: "common-close")) {
                    dismiss()
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .onAppear {
            viewState.onAppear()
        }
    }
}
