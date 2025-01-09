import SwiftUI
import AVFoundation

class AlarmDetailVoiceListState: ObservableObject {
    let chara: Chara
    var avPlayer: AVPlayer?
    var selectedCharaCall: CharaCall?

    init(chara: Chara) {
        self.chara = chara
    }

    func randomPlayAndSelecVoice() {
        selectedCharaCall = nil
        guard let randomCharaCall = chara.calls.randomElement() else {
            // TODO: なにか
            return
        }
        playVoice(url: randomCharaCall.voiceFileURL)
    }

    func playVoice(charaCall: CharaCall) {
        playVoice(url: charaCall.voiceFileURL)
    }

    private func playVoice(url: URL) {
        AudioManagerSingleton.shared.playAudio(url: url)
    }
}
