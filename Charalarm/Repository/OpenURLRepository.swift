import Foundation

struct OpenURLRepository {

    var inqueryURL: URL {
        if let lanuageCode = Locale.current.language.languageCode?.identifier, lanuageCode == "ja" {
            return URL(string: CharalarmInqueryURLForJapanese)!
        } else {
            return URL(string: CharalarmInqueryURLForEnglish)!
        }
    }

    var characterAdditionRequestURL: URL {
        if let lanuageCode = Locale.current.language.languageCode?.identifier, lanuageCode == "ja" {
            return URL(string: CharalarmCharacterAdditionRequestURLForJapanese)!
        } else {
            return URL(string: CharalarmCharacterAdditionRequestURLForEnglish)!
        }
    }

    var terms: URL {
        return URL(string: CharalarmTermsURLForJapanese)!
    }

    var privacyPolicy: URL {
        return URL(string: CharalarmPrivacyPolicyURLForJapanese)!
    }
}
