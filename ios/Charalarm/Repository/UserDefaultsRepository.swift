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

    // Defaults
    private let DEFAULT_CHARA_DOMAIN = "jp.zunko.zundamon"
    private let DEFAULT_CHARA_NAME = "ずんだもん"

    // UserDefaults の初期値を設定する
    func registerDefaults() {
        let defaults =  [KEY_CHARA_DOMAIN: DEFAULT_CHARA_DOMAIN, KEY_CHARA_NAME: DEFAULT_CHARA_NAME]
        UserDefaults.standard.register(defaults: defaults)
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

    func setDefaultCharaDomain() {
        UserDefaults.standard.set(DEFAULT_CHARA_DOMAIN, forKey: KEY_CHARA_DOMAIN)
    }

    func setDefaultCharaName() {
        UserDefaults.standard.set(DEFAULT_CHARA_DOMAIN, forKey: KEY_CHARA_NAME)
    }
}
