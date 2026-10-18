import SwiftUI
import AVFoundation

@MainActor @Observable final class CallViewState {
    let charaDomain: String
    let charaName: String
    let resourceHandler = CharaUseCase()

    var overlay = true
    var incomingAudioPlayer: AVAudioPlayer?
    var voiceAudioPlayer: AVPlayer?

    var charaThumbnailUrlString: String {
        return resourceHandler.getCharaThumbnailUrlString(charaID: charaDomain)
    }

    init(charaDomain: String, charaName: String) {
        self.charaDomain = charaDomain
        self.charaName = charaName
    }

    func call() {
        incomingAudioPlayer?.setVolume(0, fadeDuration: 1)
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            let urlString = resourceHandler.getSelfIntroductionUrlString(charaID: charaDomain)
            guard let url = URL(string: urlString) else { return }
            voiceAudioPlayer = AVPlayer(playerItem: AVPlayerItem(url: url))
            voiceAudioPlayer?.play()
        }
    }

    func incoming() {
        if let sound = NSDataAsset(name: "ringtone") {
            incomingAudioPlayer = try? AVAudioPlayer(data: sound.data)
            incomingAudioPlayer?.volume = 0.3
            incomingAudioPlayer?.play()
            incomingAudioPlayer?.setVolume(1.0, fadeDuration: 0.5)
        }
    }

    func fadeOut() {
        incomingAudioPlayer?.setVolume(0.0, fadeDuration: 0.5)
        voiceAudioPlayer?.volume = 0
    }
}
