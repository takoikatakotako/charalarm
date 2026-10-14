import Foundation
import AVFoundation
import UIKit

// MARK: - Audio Playback

/// 着信音とキャラの声の再生。
extension ConversationViewModel {

    func playRingtone() {
        guard let asset = NSDataAsset(name: Constants.ringtoneAssetName) else {
            CharalarmLogger.error("着信音アセットが見つかりません", error: ConversationError.ringtoneNotFound)
            return
        }
        audioPlayer = try? AVAudioPlayer(data: asset.data)
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }

    func stopRingtone() {
        audioPlayer?.stop()
    }

    func playVoice(_ audioData: Data) async throws {
        status = .playingVoice

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [])
        try audioSession.setActive(true)

        audioPlayer = try AVAudioPlayer(data: audioData)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()

        let success = await withCheckedContinuation { continuation in
            playbackContinuation = continuation
        }
        if !success {
            throw ConversationError.audioPlaybackFailed
        }
    }
}
