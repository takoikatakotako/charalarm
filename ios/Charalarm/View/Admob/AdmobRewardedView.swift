import GoogleMobileAds
import UIKit

/// リワード広告で使える機能。無料の人は、1日に1回広告を見るとその日は使える
enum RewardedFeature: String {
    case todaySchedule
    case trendNews

    /// その日はじめては広告なしで使えて、使い終えてホームに戻ったら広告をすすめる
    var allowsFreeFirstUse: Bool {
        self == .todaySchedule
    }

    /// 使う前に聞くときの文
    var promptMessage: String {
        switch self {
        case .todaySchedule:
            return String(localized: "rewarded-today-schedule-message")
        case .trendNews:
            return String(localized: "rewarded-trend-news-message")
        }
    }

    /// 無料の1回を使い終えて、ホームに戻ったときに聞く文
    var afterFreeUseMessage: String {
        switch self {
        case .todaySchedule:
            return String(localized: "rewarded-today-schedule-after-free-use-message")
        case .trendNews:
            return promptMessage
        }
    }
}

/// リワード広告を読み込んで出す。
/// 広告を出せないとき（ユニット ID がない、読み込めない）は、機能を止めないよう見たことにする
@MainActor final class RewardedAdPresenter: NSObject {
    private var rewardedAd: RewardedAd?
    private var continuation: CheckedContinuation<Bool, Never>?
    private var earnedReward = false

    /// リワード広告のユニット ID があるか（本番のユニットを作るまでは空）
    var isAvailable: Bool {
        !Variables.admobRewardedUnitID.isEmpty
    }

    func load() async {
        guard isAvailable, rewardedAd == nil else { return }
        do {
            let ad = try await RewardedAd.load(with: Variables.admobRewardedUnitID, request: GoogleMobileAds.Request())
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
        } catch {
            CharalarmLogger.error("リワード広告を読み込めませんでした", error: error)
        }
    }

    /// 広告を出して、最後まで見て特典を得たら true を返す。
    /// 広告を出せないときは true（機能を止めない）、途中で閉じたら false
    func present() async -> Bool {
        guard isAvailable else { return true }
        if rewardedAd == nil {
            await load()
        }
        guard let ad = rewardedAd, let viewController = Self.topViewController() else {
            return true
        }
        earnedReward = false
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            ad.present(from: viewController) { [weak self] in
                self?.earnedReward = true
            }
        }
    }

    private func finish(returning value: Bool) {
        rewardedAd = nil
        continuation?.resume(returning: value)
        continuation = nil
        // 次の分を先に読んでおく
        Task { await load() }
    }

    /// いちばん上に出ている画面（シートの上にも出せるように）
    private static func topViewController() -> UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        var viewController = windowScene?.keyWindow?.rootViewController
        while let presented = viewController?.presentedViewController {
            viewController = presented
        }
        return viewController
    }
}

extension RewardedAdPresenter: FullScreenContentDelegate {
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        CharalarmLogger.error("リワード広告を出せませんでした", error: error)
        Task { @MainActor in
            self.finish(returning: true)
        }
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.finish(returning: self.earnedReward)
        }
    }
}
