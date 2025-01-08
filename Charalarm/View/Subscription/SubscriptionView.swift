import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var viewState: SubscriptionViewState
    var body: some View {
        ZStack {
            ScrollView {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    Spacer()
                }

                VStack(spacing: 20) {

                    Text(String(localized: "subscription-message"))

                    SubscriptionCardView(
                        title: String(localized: "subscription-benefit1-title"),
                        systemImageName: "calendar",
                        description: String(localized: "subscription-benefit1-description")
                    )

                    SubscriptionCardView(
                        title: String(localized: "subscription-benefit2-title"),
                        systemImageName: "nosign",
                        description: String(localized: "subscription-benefit2-description")
                    )

                    Button {
                        viewState.upgradeButtonTapped()
                    } label: {
                        VStack(spacing: 8) {
                            Text(String(localized: "subscription-update-premium-plan"))
                                .font(Font.system(size: 20).bold())
                            Text(viewState.priceMessage)
                                .font(Font.system(size: 16).bold())
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray, lineWidth: 1)
                                .shadow(color: Color.black, radius: 16, x: 0, y: 0)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewState.restore()
                    } label: {
                        Text(String(localized: "subscription-restore"))
                    }

                    HStack {
                        Button {
                            viewState.openTeams()
                        } label: {
                            Text(String(localized: "common-terms"))
                        }
                        Button {
                            viewState.openPrivacyPolicy()
                        } label: {
                            Text(String(localized: "common-privacy"))
                        }
                    }
//                    
//                    Button {
//                        viewState.openAboutCancel()
//                    } label: {
//                        Text(R.string.localizable.subscriptionAboutCancellationMethod())
//                    }
                }
                .padding()
            }

            if viewState.enableDisplayLock {
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                        .tint(Color.white)
                        .scaleEffect(3.0)
                }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(minHeight: 0, maxHeight: .infinity)
                    .background(Color.black.opacity(0.6))
            }
        }
        .onAppear {
            viewState.onAppear()
        }
        .alert(
            viewState.alertMessage ?? "",
            isPresented: $viewState.showingAlert,
            presenting: viewState.alertMessage
        ) { entity in
            Button(String(localized: "common-close")) {
                print(entity)
            }
        } message: { entity in
            Text(entity)
        }
    }
}

struct PremiunPlanDescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView(viewState: SubscriptionViewState())
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("プレミアムプラン")
    }
}
