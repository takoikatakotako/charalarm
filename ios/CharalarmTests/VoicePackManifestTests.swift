import XCTest
@testable import CharalarmLocal

final class VoicePackManifestTests: XCTestCase {
    func testDecodesAndValidatesStyleBertVits2Pack() throws {
        let data = Data(manifest.utf8)
        let voicePack = try JSONDecoder().decode(VoicePackManifest.self, from: data)

        XCTAssertEqual(voicePack.engine, .styleBertVits2)
        XCTAssertEqual(voicePack.language, "ja-JP")
        XCTAssertNoThrow(try voicePack.validate())
    }

    func testRejectsPathTraversal() throws {
        let data = Data(manifest.replacingOccurrences(of: "model/model.onnx", with: "../model.onnx").utf8)
        let voicePack = try JSONDecoder().decode(VoicePackManifest.self, from: data)

        XCTAssertThrowsError(try voicePack.validate()) { error in
            XCTAssertEqual(error as? VoicePackManifestError, .invalidAsset("../model.onnx"))
        }
    }

    private let manifest = """
        {
          "formatVersion": 1,
          "id": "com.charalarm.alice.ja",
          "displayName": "Alice",
          "language": "ja-JP",
          "engine": "style-bert-vits2",
          "model": {
            "path": "model/model.onnx",
            "sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "size": 123456789
          },
          "styleVectors": {
            "path": "model/style_vectors.npy",
            "sha256": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "size": 1024
          },
          "textProcessor": {
            "type": "style-bert-vits2-ja",
            "dictionary": {
              "path": "language/ja/dictionary.bin",
              "sha256": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
              "size": 2048
            },
            "bertModel": {
              "path": "language/ja/bert.onnx",
              "sha256": "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
              "size": 4096
            }
          },
          "sampleRate": 44100,
          "styles": [
            { "id": 0, "name": "Neutral" }
          ]
        }
        """
}
