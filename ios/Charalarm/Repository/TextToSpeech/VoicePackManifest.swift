import Foundation

/// A versioned description of the assets required by an on-device TTS voice.
///
/// The manifest deliberately does not depend on a concrete inference engine so
/// downloaded voice packs can be validated before a runtime is selected.
struct VoicePackManifest: Codable, Equatable {
    static let supportedFormatVersion = 1

    let formatVersion: Int
    let id: String
    let displayName: String
    let language: String
    let engine: Engine
    let model: Asset
    let styleVectors: Asset?
    let textProcessor: TextProcessor
    let sampleRate: Int
    let styles: [Style]

    enum Engine: String, Codable {
        case styleBertVits2 = "style-bert-vits2"
        case voicevox
    }

    struct Asset: Codable, Equatable {
        let path: String
        let sha256: String
        let size: Int64
    }

    struct TextProcessor: Codable, Equatable {
        let type: ProcessorType
        let dictionary: Asset?
        let bertModel: Asset?

        enum ProcessorType: String, Codable {
            case styleBertVits2Japanese = "style-bert-vits2-ja"
            case styleBertVits2English = "style-bert-vits2-en"
            case openJTalk = "open-jtalk"
        }
    }

    struct Style: Codable, Equatable {
        let id: Int
        let name: String
    }

    func validate() throws {
        guard formatVersion == Self.supportedFormatVersion else {
            throw VoicePackManifestError.unsupportedFormatVersion(formatVersion)
        }
        guard !id.isEmpty, !displayName.isEmpty, !language.isEmpty else {
            throw VoicePackManifestError.missingRequiredValue
        }
        guard sampleRate > 0, !styles.isEmpty else {
            throw VoicePackManifestError.invalidAudioConfiguration
        }

        let assets = [model, styleVectors, textProcessor.dictionary, textProcessor.bertModel].compactMap { $0 }
        try assets.forEach(Self.validate(asset:))
    }

    private static func validate(asset: Asset) throws {
        // URL(fileURLWithPath:) resolves relative paths against the working directory, which hides "..".
        let components = asset.path.split(separator: "/", omittingEmptySubsequences: false)
        guard !asset.path.isEmpty,
              !asset.path.hasPrefix("/"),
              !components.contains(".."),
              asset.sha256.count == 64,
              asset.sha256.allSatisfy({ $0.isHexDigit }),
              asset.size > 0 else {
            throw VoicePackManifestError.invalidAsset(asset.path)
        }
    }
}

enum VoicePackManifestError: Error, Equatable {
    case unsupportedFormatVersion(Int)
    case missingRequiredValue
    case invalidAudioConfiguration
    case invalidAsset(String)
}
