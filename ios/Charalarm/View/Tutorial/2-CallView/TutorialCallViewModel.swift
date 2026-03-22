import SwiftUI
import AVFoundation

@Observable class TutorialCallViewModel {
    var isCalling = true
    var showingNextButton = false
    var incomingAudioPlayer: AVAudioPlayer!
    var voiceAudioPlayer: AVAudioPlayer!

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let voice = NSDataAsset(name: "jp_zunko_zundamon_call") else {
                return
            }
            self.voiceAudioPlayer = try? AVAudioPlayer(data: voice.data)
            self.voiceAudioPlayer?.play()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation {
                self.showingNextButton = true
            }
        }

    }

    func onDisappear() {
        incomingAudioPlayer?.setVolume(0.0, fadeDuration: 0.5)
        voiceAudioPlayer?.setVolume(0.0, fadeDuration: 0.5)
    }

}
