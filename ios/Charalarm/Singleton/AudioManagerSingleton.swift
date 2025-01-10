import AVFoundation

class AudioManagerSingleton {
    static let shared = AudioManagerSingleton()

    private init() {}

    private var avPlayer: AVPlayer?

    func playAudio(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer?.play()
    }

    func pauseAudio() {
        avPlayer?.pause()
    }
}
