import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State var viewState: SubscriptionViewState
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(String(localized: "subscription-message"))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)

                    SubscriptionCardView(
                        title: String(localized: "subscription-benefit1-title"),
                        systemImageName: "alarm.waves.left.and.right",
                        description: String(localized: "subscription-benefit1-description")
                    )
                    SubscriptionCardView(
                        title: String(localized: "subscription-benefit2-title"),
                        systemImageName: "nosign",
                        description: String(localized: "subscription-benefit2-description")
                    )
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button {
                        viewState.upgradeButtonTapped()
                    } label: {
                        VStack(spacing: 2) {
                            Text(String(localized: "subscription-update-premium-plan"))
                            Text(viewState.priceMessage)
                                .font(.footnote)
                        }
                    }
                    .buttonStyle(.primary)

                    HStack(spacing: 20) {
                        Button(String(localized: "subscription-restore")) {
                            viewState.restore()
                        }
                        Button(String(localized: "common-terms")) {
                            openURL(viewState.openURLRepository.terms)
                        }
                        Button(String(localized: "common-privacy")) {
                            openURL(viewState.openURLRepository.privacyPolicy)
                        }
                    }
                    .font(.footnote)
                }
                .padding(16)
                .background(.bar)
            }
            // 購入・復元の処理中は、購入・復元・閉じるを含めて画面のすべての操作を止める（StoreKit の処理を重ねて始めたり、途中で閉じたりしないように）
            .disabled(viewState.enableDisplayLock)
            .navigationTitle(String(localized: "subscription-title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseBarButton {
                        dismiss()
                    }
                    .disabled(viewState.enableDisplayLock)
                }
            }
        }
        .overlay {
            if viewState.enableDisplayLock {
                // 画面全体を覆って、タップを受け止める（ナビゲーションバーも含む）
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
                .contentShape(Rectangle())
                .accessibilityAddTraits(.isModal)
            }
        }
        .interactiveDismissDisabled(viewState.enableDisplayLock)
        .onAppear {
            viewState.onAppear()
        }
        .alert(
            viewState.alertMessage ?? "",
            isPresented: $viewState.showingAlert,
            presenting: viewState.alertMessage
        ) { _ in
            Button(String(localized: "common-close")) {}
        } message: { entity in
            Text(entity)
        }
    }
}

#Preview {
    SubscriptionView(viewState: SubscriptionViewState())
}
