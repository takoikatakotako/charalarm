import SwiftUI
import AVFoundation
import AdSupport
import AppTrackingTransparency

enum TopViewAlert {
    case failedToGetCharacterInformation
    case failedToGetCharacterSelectionInformation
    case failedToGetCharactersResources
    case failedToSetCharacterImage
    case thisFeatureIsNotAvailableInYourRegion
    case thisCharacterCannotTalkYet
    case calendarNotAuthorized

    var message: String {
        switch self {
        case .failedToGetCharacterInformation:
            return String(localized: "error-failed-to-get-character-information")
        case .failedToGetCharacterSelectionInformation:
            return String(localized: "error-failed-to-get-character-selection-information")
        case .failedToGetCharactersResources:
            return String(localized: "error-failed-to-get-characters-resources")
        case .failedToSetCharacterImage:
            return String(localized: "error-failed-to-set-character-image")
        case .thisFeatureIsNotAvailableInYourRegion:
            return String(localized: "error-this-feature-is-not-available-in-your-region")
        case .thisCharacterCannotTalkYet:
            return String(localized: "error-this-character-cannot-talk-yet")
        case .calendarNotAuthorized:
            return String(localized: "error-calendar-not-authorized")
        }
    }
}

enum TopViewSheet: Identifiable {
    /// 話題のニュースとお知らせ（タブで切り替える）
    case news
    case characterList
    case alarmList
    case config
    var id: Int {
        return hashValue
    }
}

/// トップに 3D で出すキャラ（見た目が VRM のキャラ）。
struct TopVRMChara: Equatable {
    let charaID: String
    let modelFileURL: URL
}

/// 電話ボタン・「今日の予定」ボタンで話すキャラ（fullScreenCover 用）。
struct TopConversationChara: Identifiable {
    let charaID: String
    var topic: ConversationTopic = .call
    var id: String { charaID }
}

@MainActor @Observable final class TopViewState {
    var charaImage = UIImage()
    /// まだ読んでいないお知らせがある（ベルに点を付ける）
    var hasUnreadNews = false
    /// VRM のキャラを選んでいれば、立ち絵の代わりに 3D で出す
    var vrmChara: TopVRMChara?
    var showingAlert = false
    var alert: TopViewAlert? {
        didSet {
            showingAlert = alert != nil
        }
    }
    /// 無料の人に「広告を見ると使えます」と聞いている機能
    var rewardedPrompt: RewardedFeature? {
        didSet {
            showingRewardedPrompt = rewardedPrompt != nil
        }
    }
    var showingRewardedPrompt = false
    /// 無料の1回を使い終えて、ホームに戻ったところで聞いている（見ても会話は始めず、今日を広告なしにするだけ）
    private(set) var isRewardedPromptAfterFreeUse = false
    let rewardedAd = RewardedAdPresenter()
    /// 広告を見たら始める会話
    private var pendingRewardedTopic: ConversationTopic?
    /// 無料の1回を使っている機能。会話の画面を閉じたら広告をすすめる
    private var freeUseFeature: RewardedFeature?
    var sheet: TopViewSheet?
    /// 電話ボタンで通話するキャラ。nil でなければ会話画面を出す。
    var conversationChara: TopConversationChara?
    var isPreparingCall = false
    /// 会話とタップのセリフの言語（トップと設定のどちらでも変えられる）
    var conversationLanguage: ConversationLanguage = UserDefaultsRepository().getConversationLanguage() {
        didSet {
            userDefaultsRepository.setConversationLanguage(conversationLanguage)
        }
    }
    private let userDefaultsRepository: UserDefaultsRepository = UserDefaultsRepository()
    private let fileHandler: FileRepositoryProtocol = FileRepository()

    private let localCharaResourceUseCase = LocalCharaResourceUseCase()
    private let apiRepository = APIRepository()

    /// タップしたときのセリフ（吹き出しは tapLinePlayer.text）
    let tapLinePlayer = TapLinePlayer()

    func onAppear() {
        Task {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        // 設定の画面で変えたかもしれないので読み直す
        conversationLanguage = userDefaultsRepository.getConversationLanguage()
        checkUnreadNews()

        guard let charaID = userDefaultsRepository.getCharaID() else {
            self.alert = .failedToGetCharacterSelectionInformation
            return
        }

        guard let resource = try? localCharaResourceUseCase.loadCharaResource(charaID: charaID) else {
            self.alert = .failedToGetCharactersResources
            return
        }
        setVRMChara(charaID: charaID, resource: resource)
        tapLinePlayer.load(charaID: charaID, language: conversationLanguage)

        guard let key = resource.expressions.keys.randomElement() else {
            return
        }

        setCharaImage(charaDomain: charaID, resource: resource, key: key)
    }

    func newsButtonTapped() {
        sheet = .news
    }

    /// まだ読んでいないお知らせがあるか確かめる（ベルの点）
    func checkUnreadNews() {
        Task {
            guard let latest = try? await NewsRepository().fetchNews().map(\.registeredAt).max() else { return }
            let lastSeen = userDefaultsRepository.getLastSeenNewsAt() ?? .distantPast
            hasUnreadNews = latest > lastSeen
        }
    }

    /// 話題のニュースを、キャラに読んでもらう
    @MainActor
    func readTrendNews(_ news: [TrendNews]) async {
        if needsRewardedAd(for: .trendNews) {
            // 話題の画面（シート）が閉じきってから聞く
            try? await Task.sleep(for: .milliseconds(600))
        }
        await startWithRewardedAdIfNeeded(.trendNews, topic: .trendNews(news))
    }

    func characterListButtonTapped() {
        sheet = .characterList
    }

    func alarmButtonTapped() {
        guard Locale.current.region?.identifier != "CN" else {
            alert = .thisFeatureIsNotAvailableInYourRegion
            return
        }
        sheet = .alarmList
    }

    func configButtonTapped() {
        sheet = .config
    }

    /// 電話ボタン。選んでいるキャラが会話に対応していれば、そのキャラと通話する。
    @MainActor
    func callButtonTapped() async {
        await startConversation(topic: .call)
    }

    /// 「今日の予定」ボタン。キャラが今日の予定を読み上げる（カレンダーの許可がなければ求める）。
    @MainActor
    func todayScheduleButtonTapped() async {
        let calendarRepository = CalendarRepository()
        guard calendarRepository.isAuthorized else {
            if await calendarRepository.requestAccess() {
                await startWithRewardedAdIfNeeded(.todaySchedule, topic: .todaySchedule)
            } else {
                alert = .calendarNotAuthorized
            }
            return
        }
        await startWithRewardedAdIfNeeded(.todaySchedule, topic: .todaySchedule)
    }

    // MARK: - リワード広告

    /// トップを開いたとき、無料の人のために広告を先に読んでおく
    func preloadRewardedAd() {
        guard !userDefaultsRepository.getEnablePremiumPlan() else { return }
        Task { await rewardedAd.load() }
    }

    /// 無料の人は、その日はじめて使うときに広告を見るか聞く。プレミアムの人と、今日もう見た人はそのまま始める。
    /// 無料の1回がある機能は、その日はじめては広告なしで始めて、ホームに戻ったら広告をすすめる
    private func startWithRewardedAdIfNeeded(_ feature: RewardedFeature, topic: ConversationTopic) async {
        guard needsRewardedAd(for: feature) else {
            await startConversation(topic: topic)
            return
        }
        if feature.allowsFreeFirstUse && userDefaultsRepository.getRewardedFreeUseDay(feature: feature.rawValue) != Self.today() {
            await startConversation(topic: topic)
            // 会話の画面を出せたときだけ、無料の1回を使ったことにする
            if conversationChara != nil {
                userDefaultsRepository.setRewardedFreeUseDay(feature: feature.rawValue, day: Self.today())
                freeUseFeature = feature
            }
            return
        }
        pendingRewardedTopic = topic
        isRewardedPromptAfterFreeUse = false
        rewardedPrompt = feature
    }

    /// 会話の画面を閉じてホームに戻った。無料の1回を使い終えたところなら、今日を広告なしにする広告をすすめる
    func conversationDismissed() {
        guard let feature = freeUseFeature else { return }
        freeUseFeature = nil
        guard needsRewardedAd(for: feature) else { return }
        isRewardedPromptAfterFreeUse = true
        rewardedPrompt = feature
    }

    /// 「広告を見る」を押した。最後まで見たら、その日は広告なしで使えるようにして始める。
    /// 無料の1回を使い終えたあとなら、始めずに今日を広告なしにするだけ
    func watchRewardedAd() {
        guard let feature = rewardedPrompt else { return }
        let topic = pendingRewardedTopic
        rewardedPrompt = nil
        pendingRewardedTopic = nil
        Task {
            guard await rewardedAd.present() else { return }
            userDefaultsRepository.setRewardedUnlockedDay(feature: feature.rawValue, day: Self.today())
            if let topic {
                await startConversation(topic: topic)
            }
        }
    }

    func cancelRewardedAd() {
        rewardedPrompt = nil
        pendingRewardedTopic = nil
    }

    private func needsRewardedAd(for feature: RewardedFeature) -> Bool {
        !userDefaultsRepository.getEnablePremiumPlan()
            && rewardedAd.isAvailable
            && userDefaultsRepository.getRewardedUnlockedDay(feature: feature.rawValue) != Self.today()
    }

    private static func today() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    @MainActor
    private func startConversation(topic: ConversationTopic) async {
        guard !isPreparingCall else { return }
        guard let charaID = userDefaultsRepository.getCharaID() else {
            alert = .failedToGetCharacterSelectionInformation
            return
        }

        isPreparingCall = true
        defer { isPreparingCall = false }
        do {
            let chara = try await apiRepository.fetchCharacter(charaID: charaID)
            guard chara.conversation != nil else {
                alert = .thisCharacterCannotTalkYet
                return
            }
            conversationChara = TopConversationChara(charaID: charaID, topic: topic)
        } catch {
            CharalarmLogger.error("キャラ情報の取得に失敗", error: error)
            alert = .failedToGetCharacterInformation
        }
    }

    /// キャラをタップした。タップのセリフがあれば今の日時に合うものを、なければ表情のボイスを流す
    func tapped() {
        guard let charaDomain = userDefaultsRepository.getCharaID() else {
            self.alert = .failedToGetCharacterSelectionInformation
            return
        }

        guard let resource = try? localCharaResourceUseCase.loadCharaResource(charaID: charaDomain) else {
            self.alert = .failedToGetCharactersResources
            return
        }

        if tapLinePlayer.hasLines(charaID: charaDomain) {
            tapLinePlayer.play(charaID: charaDomain, language: conversationLanguage)
            return
        }
        // 古いデータ: キャラを選んだときにボイスをダウンロードしてあるセリフ
        if let tapLines = resource.tapLines, !tapLines.isEmpty {
            tapLinePlayer.playDownloaded(charaID: charaDomain, lines: tapLines, language: conversationLanguage)
            return
        }

        guard let key = resource.expressions.keys.randomElement() else {
            return
        }

        setCharaImage(charaDomain: charaDomain, resource: resource, key: key)
        playCharaVoice(charaDomain: charaDomain, resource: resource, key: key)
    }

    func updateChara(charaID: String?) {
        guard let charaID = charaID else {
            alert = .failedToGetCharacterSelectionInformation
            return
        }

        guard let resource = try? localCharaResourceUseCase.loadCharaResource(charaID: charaID) else {
            alert = .failedToGetCharactersResources
            return
        }
        setVRMChara(charaID: charaID, resource: resource)
        tapLinePlayer.load(charaID: charaID, language: conversationLanguage)

        guard let key = resource.expressions.keys.randomElement() else {
            return
        }

        setCharaImage(charaDomain: charaID, resource: resource, key: key)
    }

    /// ユーザーが選んだ見た目（なければ既定）が 3D なら 3D で出す。イラストを選んでも画像がなければ 3D にする
    private func setVRMChara(charaID: String, resource: LocalCharaResource) {
        guard let modelFileURL = resource.modelFileURL else {
            vrmChara = nil
            return
        }
        let preferred = userDefaultsRepository.getPreferredAppearance(charaID: charaID)
            ?? resource.defaultAppearance.flatMap(CharaAppearanceKind.init(rawValue:))
        let hasImage = resource.expressions.values.contains { !$0.imageFileNames.isEmpty }
        if preferred == .illustration && hasImage {
            vrmChara = nil
        } else {
            vrmChara = TopVRMChara(charaID: charaID, modelFileURL: modelFileURL)
        }
    }

    private func setCharaImage(charaDomain: String, resource: LocalCharaResource, key: String) {
        guard let imageName = resource.expressions[key]?.imageFileNames.randomElement() else {
            return
        }

        do {
            let data = try fileHandler.loadData(directoryName: charaDomain, fileName: imageName)
            guard let image = UIImage(data: data) else {
                alert = .failedToSetCharacterImage
                return
            }
            charaImage = image
        } catch {
            alert = .failedToSetCharacterImage
        }
    }

    private func playCharaVoice(charaDomain: String, resource: LocalCharaResource, key: String) {
        guard let voiceName = resource.expressions[key]?.voiceFileNames.randomElement() else {
            return
        }

        do {
            tapLinePlayer.playVoice(try fileHandler.loadData(directoryName: charaDomain, fileName: voiceName))
        } catch {
            CharalarmLogger.error("表情のボイスを読めませんでした", error: error)
        }
    }
}
