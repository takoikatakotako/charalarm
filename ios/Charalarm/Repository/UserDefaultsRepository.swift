import Foundation

protocol UserDefaultsRepositoryProtocol {
    func registerDefaults()
    func getCharaID() -> String?
    func setCharaDomain(charaDomain: String)
    func getCharaName() -> String?
    func setCharaName(charaName: String)
    func getEnablePremiumPlan() -> Bool
    func setEnablePremiumPlan(enable: Bool)
    func setDefaultCharaDomain()
    func setDefaultCharaName()
}

struct UserDefaultsRepository: UserDefaultsRepositoryProtocol {
    // Keys
    private let KEY_CHARA_DOMAIN = "CHARA_DOMAIN"
    private let KEY_CHARA_NAME = "CHARA_NAME"
    private let KEY_ENABLE_PREMIUM_PLAN = "ENABLE_PREMIUM_PLAN"
    private let KEY_PREFERRED_APPEARANCE_PREFIX = "PREFERRED_APPEARANCE_"
    private let KEY_CONVERSATION_LANGUAGE = "CONVERSATION_LANGUAGE"
    private let KEY_USE_CALENDAR_IN_CONVERSATION = "USE_CALENDAR_IN_CONVERSATION"
    private let KEY_MENTION_SCHEDULE_ON_CALL = "MENTION_SCHEDULE_ON_CALL"
    private let KEY_EXCLUDED_CALENDAR_IDS = "EXCLUDED_CALENDAR_IDS"
    private let KEY_TAP_VOICE_IN_SILENT_MODE = "TAP_VOICE_IN_SILENT_MODE"
    private let KEY_LAST_SEEN_NEWS_AT = "LAST_SEEN_NEWS_AT"
    private let KEY_NEEDS_PURCHASE_SYNC_TO_REVENUECAT = "NEEDS_PURCHASE_SYNC_TO_REVENUECAT"
    private let KEY_REWARDED_UNLOCKED_DAY_PREFIX = "REWARDED_UNLOCKED_DAY_"
    private let KEY_REWARDED_FREE_USE_DAY_PREFIX = "REWARDED_FREE_USE_DAY_"

    // Defaults
    private let DEFAULT_CHARA_DOMAIN = "com.charalarm.yui"
    private let DEFAULT_CHARA_NAME = "井上結衣"

    // UserDefaults の初期値を設定する
    func registerDefaults() {
        let defaults =  [KEY_CHARA_DOMAIN: DEFAULT_CHARA_DOMAIN, KEY_CHARA_NAME: DEFAULT_CHARA_NAME]
        UserDefaults.standard.register(defaults: defaults)
    }

    /// キャラを保存したことがあるか（registerDefaults の初期値ではなく）
    func hasSavedCharaDomain() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        return UserDefaults.standard.persistentDomain(forName: bundleID)?[KEY_CHARA_DOMAIN] != nil
    }

    func getCharaID() -> String? {
        guard let charaDomain = UserDefaults.standard.string(forKey: KEY_CHARA_DOMAIN) else {
            return nil
        }
        return charaDomain
    }

    func setCharaDomain(charaDomain: String) {
        UserDefaults.standard.set(charaDomain, forKey: KEY_CHARA_DOMAIN)
    }

    func getCharaName() -> String? {
        guard let charaName = UserDefaults.standard.string(forKey: KEY_CHARA_NAME) else {
            return nil
        }
        return charaName
    }

    func setCharaName(charaName: String) {
        UserDefaults.standard.set(charaName, forKey: KEY_CHARA_NAME)
    }

    func getEnablePremiumPlan() -> Bool {
        UserDefaults.standard.bool(forKey: KEY_ENABLE_PREMIUM_PLAN)
    }

    func setEnablePremiumPlan(enable: Bool) {
        UserDefaults.standard.set(enable, forKey: KEY_ENABLE_PREMIUM_PLAN)
    }

    /// キャラ詳細でユーザーが選んだ見た目（3D / イラスト）。選んでいなければ nil。
    func getPreferredAppearance(charaID: String) -> CharaAppearanceKind? {
        UserDefaults.standard.string(forKey: KEY_PREFERRED_APPEARANCE_PREFIX + charaID).flatMap(CharaAppearanceKind.init(rawValue:))
    }

    func setPreferredAppearance(charaID: String, kind: CharaAppearanceKind) {
        UserDefaults.standard.set(kind.rawValue, forKey: KEY_PREFERRED_APPEARANCE_PREFIX + charaID)
    }

    /// 会話の言語。選んでいなければ端末の言語
    func getConversationLanguage() -> ConversationLanguage {
        UserDefaults.standard.string(forKey: KEY_CONVERSATION_LANGUAGE).flatMap(ConversationLanguage.init(rawValue:))
            ?? .deviceDefault
    }

    func setConversationLanguage(_ language: ConversationLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: KEY_CONVERSATION_LANGUAGE)
    }

    /// 会話で今日の予定を使う（予定のタイトルと時刻を /chat に送る）。最初はオフ
    func getUseCalendarInConversation() -> Bool {
        UserDefaults.standard.bool(forKey: KEY_USE_CALENDAR_IN_CONVERSATION)
    }

    func setUseCalendarInConversation(_ use: Bool) {
        UserDefaults.standard.set(use, forKey: KEY_USE_CALENDAR_IN_CONVERSATION)
    }

    /// 電話の最初に、キャラのほうから今日の予定に触れる（毎回、予定のタイトルと時刻を送る）。最初はオフ
    func getMentionScheduleOnCall() -> Bool {
        UserDefaults.standard.bool(forKey: KEY_MENTION_SCHEDULE_ON_CALL)
    }

    func setMentionScheduleOnCall(_ mention: Bool) {
        UserDefaults.standard.set(mention, forKey: KEY_MENTION_SCHEDULE_ON_CALL)
    }

    /// 読んだいちばん新しいお知らせの日時（それより新しいお知らせがあればベルに点を付ける）
    func getLastSeenNewsAt() -> Date? {
        UserDefaults.standard.object(forKey: KEY_LAST_SEEN_NEWS_AT) as? Date
    }

    func setLastSeenNewsAt(_ date: Date) {
        UserDefaults.standard.set(date, forKey: KEY_LAST_SEEN_NEWS_AT)
    }

    /// RevenueCat を入れる前に買ったサブスクを、RevenueCat に送る必要があるか。まだ決めていなければ nil
    func getNeedsPurchaseSyncToRevenueCat() -> Bool? {
        UserDefaults.standard.object(forKey: KEY_NEEDS_PURCHASE_SYNC_TO_REVENUECAT) as? Bool
    }

    func setNeedsPurchaseSyncToRevenueCat(_ needsSync: Bool) {
        UserDefaults.standard.set(needsSync, forKey: KEY_NEEDS_PURCHASE_SYNC_TO_REVENUECAT)
    }

    /// リワード広告を見て、その機能を使えるようにした日（yyyy-MM-dd）
    func getRewardedUnlockedDay(feature: String) -> String? {
        UserDefaults.standard.string(forKey: KEY_REWARDED_UNLOCKED_DAY_PREFIX + feature)
    }

    func setRewardedUnlockedDay(feature: String, day: String) {
        UserDefaults.standard.set(day, forKey: KEY_REWARDED_UNLOCKED_DAY_PREFIX + feature)
    }

    /// 広告なしの無料の1回を使った日（yyyy-MM-dd）
    func getRewardedFreeUseDay(feature: String) -> String? {
        UserDefaults.standard.string(forKey: KEY_REWARDED_FREE_USE_DAY_PREFIX + feature)
    }

    func setRewardedFreeUseDay(feature: String, day: String) {
        UserDefaults.standard.set(day, forKey: KEY_REWARDED_FREE_USE_DAY_PREFIX + feature)
    }

    /// マナーモードでも、ホームでタップしたときの声を出す。最初はオフ（マナーモードでは鳴らさない）
    func getTapVoiceInSilentMode() -> Bool {
        UserDefaults.standard.bool(forKey: KEY_TAP_VOICE_IN_SILENT_MODE)
    }

    func setTapVoiceInSilentMode(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: KEY_TAP_VOICE_IN_SILENT_MODE)
    }

    /// 予定を読まないカレンダー（EKCalendar.calendarIdentifier）。一度も選んでいなければ nil
    func getExcludedCalendarIDs() -> Set<String>? {
        UserDefaults.standard.stringArray(forKey: KEY_EXCLUDED_CALENDAR_IDS).map(Set.init)
    }

    func setExcludedCalendarIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids).sorted(), forKey: KEY_EXCLUDED_CALENDAR_IDS)
    }

    func setDefaultCharaDomain() {
        UserDefaults.standard.set(DEFAULT_CHARA_DOMAIN, forKey: KEY_CHARA_DOMAIN)
    }

    func setDefaultCharaName() {
        UserDefaults.standard.set(DEFAULT_CHARA_NAME, forKey: KEY_CHARA_NAME)
    }
}
