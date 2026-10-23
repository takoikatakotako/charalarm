import UIKit
import AVFoundation
import Firebase
import UserNotifications
import PushKit
import CallKit
import AVKit
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate {
    let model = AppDelegateModel(apiRepository: APIRepository(), keychainRepository: KeychainRepository())

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Use Firebase library to configure APIs.
        FirebaseApp.configure()

        // Initialize the Google Mobile Ads SDK.
        MobileAds.shared.start()

        // 課金（RevenueCat）。購入状態の変化を見張る
        SubscriptionRepository().configure()

        //
        model.registerDefaults()

        // プッシュ通知を要求
        UIApplication.shared.registerForRemoteNotifications()

        // VoIP Pushを要求
        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]

        // バックグラウンドでの音声再生を有効化する
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            assertionFailure("ERROR: CANNOT PLAY MUSIC IN BACKGROUND. Message from code: \"\(error)\"")
        }

        #if DEBUG
        // 端末内 VOICEVOX 合成の疎通確認 (VOICEVOX_POC=1 起動時のみ)
        VoicevoxPoC.runIfEnabled()
        #endif

        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        // 課金の状態は RevenueCat が前に戻ったときに取り直し、SubscriptionRepository が受け取る
    }
}

// MARK: - Push Notification
extension AppDelegate {
    // プッシュ通知の利用登録が成功した場合
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        model.registerPushToken(token: token)
    }

    // プッシュ通知の利用登録が失敗した場合
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        model.failToRregisterPushToken(error: error)
    }
}

// MARK: - VoIP Push Notification
extension AppDelegate: PKPushRegistryDelegate {
    // VoIP Push トークンを取得
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        model.registerVoipPushToken(token: token)
    }

    // VoIP Pushを受信
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        // ペイロードのパース
        if let aps = payload.dictionaryPayload["aps"] as? NSDictionary,
           let alert = aps["alert"] as? String,
           let data = alert.data(using: .utf8),
           let dataDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
           let charaNeme = dataDictionary["charaName"],
           let voiceFileURL = dataDictionary["voiceFileURL"] {
            model.setCharaID(charaID: dataDictionary["charaID"] ?? "")
            model.setCharaName(charaName: charaNeme)
            model.setVoiceFileURL(voiceFileURL: voiceFileURL)
        }

        // 通話画面を表示
        let config = CXProviderConfiguration()
        config.iconTemplateImageData = UIImage(resource: .callAlarm).pngData()
        config.includesCallsInRecents = true
        let provider = CXProvider(configuration: config)
        provider.setDelegate(self, queue: nil)
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: model.charaName)
        provider.reportNewIncomingCall(with: UUID(), update: update, completion: { _ in })
    }
}

extension AppDelegate: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {}

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
        model.answerCall(callUUID: action.callUUID)
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        model.receiveVoipPush()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
        model.endCall()
    }
}
