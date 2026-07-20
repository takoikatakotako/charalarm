import Foundation
import voicevox_core

/// VOICEVOX CORE を端末内で動かし、指定スタイルID の音声を合成する。
/// 辞書・音声モデルはアプリバンドルにフォルダ参照として同梱している。
class VoicevoxRepository: TextToSpeechRepository {

    private var synthesizer: OpaquePointer?

    func setupSynthesizer() throws {
        // VoicevoxInitializeOptions を生成
        let initializeOptions: VoicevoxInitializeOptions = voicevox_make_default_initialize_options()

        // Onnxruntime を初期化
        var onnxruntime: OpaquePointer? = voicevox_onnxruntime_get()
        let onnxruntimeInitResultCode = voicevox_onnxruntime_init_once(&onnxruntime)
        guard onnxruntimeInitResultCode == 0 else {
            throw VoicevoxError.onnxruntimeInitFailed
        }

        // Open JTalk 辞書をバンドルから読み込み
        let bundlePath = Bundle.main.resourcePath!
        let bundleURL = URL(fileURLWithPath: bundlePath)
        let openJTalkDirectory = bundleURL.appendingPathComponent("open_jtalk_dic_utf_8-1.11")
        let openJTalkDicDir: UnsafeMutablePointer<CChar>! = strdup(openJTalkDirectory.path())
        defer { free(openJTalkDicDir) }
        var openJtalk: OpaquePointer?
        let openJtalkRcNewResultCode: Int32 = voicevox_open_jtalk_rc_new(openJTalkDicDir, &openJtalk)
        guard openJtalkRcNewResultCode == 0 else {
            throw VoicevoxError.openJTalkRCNewFailed
        }

        // Synthesizer を生成
        let synthesizerNewResultCode = voicevox_synthesizer_new(onnxruntime, openJtalk, initializeOptions, &synthesizer)
        guard synthesizerNewResultCode == 0 else {
            throw VoicevoxError.synthesizerNewFailed
        }
        voicevox_open_jtalk_rc_delete(openJtalk)

        // 音声モデル (0.vvm) をバンドルから読み込み
        let voiceModelFileURL = bundleURL
            .appendingPathComponent("vvms")
            .appendingPathComponent("0.vvm")
        let voiceModelPath: UnsafeMutablePointer<CChar>! = strdup(voiceModelFileURL.path())
        defer { free(voiceModelPath) }
        var voiceModelFile: OpaquePointer?
        let voiceModelFileOpenResultCode: Int32 = voicevox_voice_model_file_open(voiceModelPath, &voiceModelFile)
        guard voiceModelFileOpenResultCode == 0 else {
            throw VoicevoxError.voiceModelFileOpenFailed
        }

        let synthesizerLoadVoiceModelResultCode = voicevox_synthesizer_load_voice_model(synthesizer, voiceModelFile)
        guard synthesizerLoadVoiceModelResultCode == 0 else {
            throw VoicevoxError.synthesizerLoadVoiceModelFailed
        }
        voicevox_voice_model_file_delete(voiceModelFile)
    }

    func synthesize(text: String, styleId: Int) async throws -> Data {
        let voicevoxTtsOptions = voicevox_make_default_tts_options()
        let cText = strdup(text)
        defer { free(cText) }
        var wavLength: UInt = 0
        var wavBuffer: UnsafeMutablePointer<UInt8>?
        let synthesizerTtsResultCode = voicevox_synthesizer_tts(
            synthesizer, cText, VoicevoxStyleId(styleId), voicevoxTtsOptions, &wavLength, &wavBuffer
        )
        guard synthesizerTtsResultCode == 0 else {
            throw VoicevoxError.synthesizerTextToSpeechFailed
        }

        guard let wavBuffer = wavBuffer else {
            throw VoicevoxError.waveBufferNil
        }
        let data = Data(bytes: wavBuffer, count: Int(wavLength))
        voicevox_wav_free(wavBuffer)
        return data
    }

    func cleanupSynthesizer() {
        if let synthesizer = synthesizer {
            voicevox_synthesizer_delete(synthesizer)
            self.synthesizer = nil
        }
    }

    deinit {
        cleanupSynthesizer()
    }
}
