import Foundation

class Variables {
    static let shared = Variables()

    private init() {}

    // APIのエンドポイント
    static var apiEndpoint: String {
        return Bundle.main.infoDictionary?["API_ENDPOINT"] as? String ?? ""
    }
    private(set) var apiEndpoint: String = ""
    func setApiEndpoint(_ endpoint: String) {
        self.apiEndpoint = endpoint
    }

    // リソースのエンドポイント
    static var resourceEndpoint: String {
        return Bundle.main.infoDictionary?["RESOURCE_ENDPOINT"] as? String ?? ""
    }
    private(set) var resourceEndpoint: String = ""
    func setResourceEndpoint(_ endpoint: String) {
        self.resourceEndpoint = endpoint
    }

    // AdmobのユニットID: AlarmList
    static var admobAlarmListUnitID: String {
        return Bundle.main.infoDictionary?["ADMOB_ALARM_LIST"] as? String ?? ""
    }
    private(set) var admobAlarmListUnitID: String = ""
    func setAdmobAlarmListUnitID(_ unitID: String) {
        self.admobAlarmListUnitID = unitID
    }

    // AdmobのユニットID: Config
    static var admobConfigUnitID: String {
        return Bundle.main.infoDictionary?["ADMOB_CONFIG"] as? String ?? ""
    }
    private(set) var admobConfigUnitID: String = ""
    func setAdmobilConfigUnitID(_ unitID: String) {
        self.admobConfigUnitID = unitID
    }

    // サブスクのIDを取得
    static var subscriptionProductID: String {
        return Bundle.main.infoDictionary?["SUBSCRIPTION_PRODUCT_ID"] as? String ?? ""
    }
    private(set) var subscriptionProductID: String = ""
    func setSubscriptionProductID(_ productID: String) {
        self.subscriptionProductID = productID
    }

    // Datadog Client Token
    static var datadogClientToken: String {
        return Bundle.main.infoDictionary?["DATADOG_CLIENT_TOKEN"] as? String ?? ""
    }
    private(set) var datadogClientToken: String = ""
    func setDataDogClientToken(_ token: String) {
        self.datadogClientToken = token
    }

    // Datadog Log Environment
    static var datadogLogENV: String {
        return Bundle.main.infoDictionary?["DATADOG_LOG_ENV"] as? String ?? ""
    }
    private(set) var datadogLogENV: String = ""
    func setDataDogLogENV(_ env: String) {
        self.datadogLogENV = env
    }

    // Datadog Log Service
    static var datadogLogService: String {
        return Bundle.main.infoDictionary?["DATADOG_LOG_SERVICE"] as? String ?? ""
    }
    private(set) var datadogLogService: String = ""
    func setDataDogLogService(_ service: String) {
        self.datadogLogService = service
    }

    // Push Token
    private(set) var pushToken: String = ""
    func setPushToken(_ pushToken: String) {
        self.pushToken = pushToken
    }

    // VoIP Push Token
    private(set) var voipPushToken: String = ""
    func setVoipPushToken(_ voipPushToken: String) {
        self.voipPushToken = voipPushToken
    }
}
