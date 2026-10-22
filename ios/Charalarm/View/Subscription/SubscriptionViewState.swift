import RevenueCat
import StoreKit

@MainActor @Observable final class SubscriptionViewState {
    var product: StoreProduct?
    var enableDisplayLock: Bool = false
    var showingAlert: Bool = false
    var alertMessage: String?

    private let subscriptionRepository = SubscriptionRepository()
    let openURLRepository = OpenURLRepository()

    var priceMessage: String {
        guard let product else {
            return "-- / --"
        }
        if let period = product.sk2Product?.subscription?.subscriptionPeriod {
            return "\(product.localizedPriceString) / \(period.unit.localizedDescription)"
        }
        return product.localizedPriceString
    }

    func onAppear() {
        Task { @MainActor in
            do {
                product = try await subscriptionRepository.fetchProduct()
                if product == nil {
                    throw SubscribeError.productUnavailable
                }
            } catch {
                CharalarmLogger.error("サブスクの情報を取れませんでした", error: error)
                alertMessage = String(localized: "error-failed-to-get-subscription-info")
                showingAlert = true
            }
        }
    }

    func upgradeButtonTapped() {
        guard let product else {
            alertMessage = String(localized: "error-failed-to-get-subscription-info")
            showingAlert = true
            return
        }

        Task { @MainActor in
            enableDisplayLock = true
            defer { enableDisplayLock = false }
            do {
                guard try await subscriptionRepository.purchase(product: product) else {
                    // 買えたのにプレミアムにならない（RevenueCat の Entitlement の設定漏れなど）
                    CharalarmLogger.error("購入後にプレミアムプランが有効になりませんでした")
                    alertMessage = String(localized: "error-failed-to-update-premium-plan")
                    showingAlert = true
                    return
                }
            } catch SubscribeError.userCancelled {
                // 自分でやめたので何も出さない
            } catch {
                CharalarmLogger.error("サブスクを買えませんでした", error: error)
                alertMessage = String(localized: "error-failed-to-update-premium-plan")
                showingAlert = true
            }
        }
    }

    func restore() {
        Task { @MainActor in
            enableDisplayLock = true
            defer { enableDisplayLock = false }
            do {
                guard try await subscriptionRepository.restore() else {
                    // 有効なサブスクリプションがない（復元するものがない）
                    alertMessage = String(localized: "error-failed-to-find-purchase-history")
                    showingAlert = true
                    return
                }
                alertMessage = String(localized: "subscription-restore-success")
                showingAlert = true
            } catch {
                CharalarmLogger.error("サブスクを復元できませんでした", error: error)
                alertMessage = String(localized: "error-failed-to-subscription-restore")
                showingAlert = true
            }
        }
    }
}
