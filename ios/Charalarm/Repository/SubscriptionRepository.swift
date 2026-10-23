import Foundation
import RevenueCat

/// プレミアムプラン（サブスク）の購入・復元・状態を RevenueCat で扱う。
/// RevenueCat のユーザー ID にはアプリのユーザー ID を使い、サーバは RevenueCat の Webhook で購入状態を受け取る。
struct SubscriptionRepository {
    /// プレミアムプランの Entitlement（RevenueCat のダッシュボードで作ったもの）
    static let entitlementID = "premium"

    private let keychainRepository = KeychainRepository()
    private let userDefaultsRepository = UserDefaultsRepository()

    /// 起動時に一度だけ呼ぶ。登録済みならそのユーザー ID で始め、購入状態の変化を見張る
    func configure() {
        let apiKey = Variables.revenueCatAPIKey
        guard !apiKey.isEmpty, !Purchases.isConfigured else {
            return
        }
        #if DEBUG
        Purchases.logLevel = .info
        #endif
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                .with(appUserID: keychainRepository.getUserID())
                .build()
        )

        // 移行が要るかは、購入状態の見張りでプレミアムの印が書き換わる前に決めておく
        let needsPurchaseSync = needsPurchaseSyncFromStoreKit()
        Task {
            if needsPurchaseSync {
                await syncPurchasesFromStoreKit()
            }
            for await customerInfo in Purchases.shared.customerInfoStream {
                updatePremiumPlan(customerInfo)
            }
        }
    }

    /// ユーザー登録が済んだら、そのユーザー ID に切り替える（それまでの購入は引き継がれる）
    func logIn(userID: String) async {
        guard Purchases.isConfigured else { return }
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userID)
            updatePremiumPlan(customerInfo)
        } catch {
            CharalarmLogger.error("RevenueCat にログインできませんでした", error: error)
        }
    }

    /// 退会したら、RevenueCat も匿名のユーザーに戻す
    func logOut() async {
        guard Purchases.isConfigured, !Purchases.shared.isAnonymous else { return }
        _ = try? await Purchases.shared.logOut()
        userDefaultsRepository.setEnablePremiumPlan(enable: false)
    }

    /// 売っているサブスク。RevenueCat の Offering があればそれを、なければ商品 ID で探す
    func fetchProduct() async throws -> StoreProduct? {
        guard Purchases.isConfigured else {
            throw SubscribeError.productUnavailable
        }
        if let package = try await Purchases.shared.offerings().current?.availablePackages.first {
            return package.storeProduct
        }
        return try await Purchases.shared.products([Variables.subscriptionProductID]).first
    }

    /// 買う。プレミアムになったかを返す
    func purchase(product: StoreProduct) async throws -> Bool {
        let result: PurchaseResultData
        do {
            result = try await Purchases.shared.purchase(product: product)
        } catch let error as ErrorCode where error == .purchaseCancelledError {
            throw SubscribeError.userCancelled
        } catch let error as ErrorCode where error == .paymentPendingError {
            throw SubscribeError.pending
        } catch let error as ErrorCode where error == .purchaseNotAllowedError {
            throw SubscribeError.purchaseNotAllowed
        }
        if result.userCancelled {
            throw SubscribeError.userCancelled
        }
        updatePremiumPlan(result.customerInfo)
        return isPremium(result.customerInfo)
    }

    /// 前に買ったサブスクを取り戻す。プレミアムになったかを返す
    func restore() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        updatePremiumPlan(customerInfo)
        return isPremium(customerInfo)
    }

    private func isPremium(_ customerInfo: CustomerInfo) -> Bool {
        customerInfo.entitlements[Self.entitlementID]?.isActive == true
    }

    private func updatePremiumPlan(_ customerInfo: CustomerInfo) {
        userDefaultsRepository.setEnablePremiumPlan(enable: isPremium(customerInfo))
    }

    /// RevenueCat を入れる前に StoreKit で買った人か。初めて決めたときの答えを取っておき、送れるまで使う
    private func needsPurchaseSyncFromStoreKit() -> Bool {
        if let needsSync = userDefaultsRepository.getNeedsPurchaseSyncToRevenueCat() {
            return needsSync
        }
        let needsSync = userDefaultsRepository.getEnablePremiumPlan()
        userDefaultsRepository.setNeedsPurchaseSyncToRevenueCat(needsSync)
        return needsSync
    }

    /// StoreKit で買った購入を RevenueCat に送る。失敗したら次の起動でもう一度送る
    private func syncPurchasesFromStoreKit() async {
        do {
            let customerInfo = try await Purchases.shared.syncPurchases()
            updatePremiumPlan(customerInfo)
            userDefaultsRepository.setNeedsPurchaseSyncToRevenueCat(false)
        } catch {
            CharalarmLogger.error("RevenueCat に購入を送れませんでした", error: error)
        }
    }
}
