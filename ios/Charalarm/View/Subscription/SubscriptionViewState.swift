import StoreKit

class SubscriptionViewState: ObservableObject {
    @Published var product: Product?
    @Published var enableDisplayLock: Bool = false
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String?

    private let apiRepository = APIRepository()
    private let userDefaultsRepository = UserDefaultsRepository()
    private let openURLRepository = OpenURLRepository()

    var priceMessage: String {
        if let product = product, let period = product.subscription?.subscriptionPeriod {
            return "\(product.displayPrice) / \(period.unit)"
        } else {
            return "-- / --"
        }
    }

    func onAppear() {
        Task { @MainActor in
            do {
                let product = try await fetchProducts()
                self.product = product
            } catch {
                alertMessage = String(localized: "error-failed-to-get-subscription-info")
                showingAlert = true
            }
        }
    }

    @MainActor
    func upgradeButtonTapped() {
        guard let product = self.product else {
            alertMessage = String(localized: "error-failed-to-get-subscription-info")
            showingAlert = true
            return
        }

        Task { @MainActor in
            enableDisplayLock = true
            do {
                let transaction = try await purchase(product: product)
                userDefaultsRepository.setEnablePremiumPlan(enable: true)
                await transaction.finish()
                enableDisplayLock = false
            } catch {
                enableDisplayLock = false
                alertMessage = String(localized: "error-failed-to-update-premium-plan")
                showingAlert = true
            }
        }
    }

    func restore() {
        Task { @MainActor in
            enableDisplayLock = true

            do {
                try await AppStore.sync()

                var validSubscription: Transaction?
                for await verificationResult in Transaction.currentEntitlements {
                    if case .verified(let transaction) = verificationResult,
                       transaction.productType == .autoRenewable && !transaction.isUpgraded {
                        validSubscription = transaction
                    }
                }

                guard validSubscription?.productID == nil else {
                    // リストア対象じゃない場合
                    enableDisplayLock = false
                    alertMessage = String(localized: "error-failed-to-find-purchase-history")
                    showingAlert = true
                    return
                }

                // 特典を付与
                userDefaultsRepository.setEnablePremiumPlan(enable: true)
                alertMessage = String(localized: "subscription-restore-success")
                showingAlert = true
            } catch {
                enableDisplayLock = false
                alertMessage = String(localized: "error-failed-to-subscription-restore")
                showingAlert = true
            }
        }
    }

    func openTeams() {
        let url = openURLRepository.terms
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func openPrivacyPolicy() {
        let url = openURLRepository.privacyPolicy
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func openAboutCancel() {
        let url = openURLRepository.privacyPolicy
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func fetchProducts() async throws -> Product? {
        let productIdList = [Variables.subscriptionProductID]
        let products: [Product] = try await Product.products(for: productIdList)
        guard let product = products.first else {
            return nil
        }
        return product
    }

    private func purchase(product: Product) async throws -> Transaction {
        // Product.PurchaseResultの取得
        let purchaseResult: Product.PurchaseResult
        do {
            purchaseResult = try await product.purchase()
        } catch Product.PurchaseError.productUnavailable {
            throw SubscribeError.productUnavailable
        } catch Product.PurchaseError.purchaseNotAllowed {
            throw SubscribeError.purchaseNotAllowed
        } catch {
            throw SubscribeError.otherError
        }

        // VerificationResultの取得
        let verificationResult: VerificationResult<Transaction>
        switch purchaseResult {
        case .success(let result):
            verificationResult = result
        case .userCancelled:
            throw SubscribeError.userCancelled
        case .pending:
            throw SubscribeError.pending
        @unknown default:
            throw SubscribeError.otherError
        }

        // Transactionの取得
        switch verificationResult {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw SubscribeError.failedVerification
        }
    }
}
