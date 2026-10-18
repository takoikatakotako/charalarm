import SwiftUI
import AVFoundation

@MainActor @Observable final class TutorialCallViewState {
    var isCalling = true
    var showingNextButton = false
    private var incomingAudioPlayer: AVAudioPlayer?
    private var voiceAudioPlayer: AVAudioPlayer?

    func onAppear() {
        if let sound = NSDataAsset(name: "ringtone") {
            incomingAudioPlayer = try? AVAudioPlayer(data: sound.data)
            incomingAudioPlayer?.volume = 0.3
            incomingAudioPlayer?.play()
            incomingAudioPlayer?.setVolume(1.0, fadeDuration: 0.5)
        }
    }

    func callButtonTapped() {
        incomingAudioPlayer?.setVolume(0, fadeDuration: 1)
        withAnimation {
            self.isCalling = false
        }

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if let voice = NSDataAsset(name: "jp_zunko_zundamon_call") {
                voiceAudioPlayer = try? AVAudioPlayer(data: voice.data)
                voiceAudioPlayer?.play()
            }
            try? await Task.sleep(for: .seconds(3))
            withAnimation {
                showingNextButton = true
            }
        }
    }

    func onDisappear() {
        incomingAudioPlayer?.setVolume(0.0, fadeDuration: 0.5)
        voiceAudioPlayer?.setVolume(0.0, fadeDuration: 0.5)
    }

}
