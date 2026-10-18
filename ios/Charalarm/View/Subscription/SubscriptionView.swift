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
            .overlay {
                if viewState.enableDisplayLock {
                    ProgressView()
                        .controlSize(.large)
                        .padding(32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .navigationTitle(String(localized: "subscription-title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseBarButton {
                        dismiss()
                    }
                }
            }
        }
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
