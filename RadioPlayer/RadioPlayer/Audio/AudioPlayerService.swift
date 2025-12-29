import AVFoundation
import MediaPlayer

final class AudioPlayerService: NSObject, AudioPlaying {
    var onEvent: ((AudioPlayerEvent) -> Void)?

    private let player = AVPlayer()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let nowPlaying = MPNowPlayingInfoCenter.default()
    private var didRegisterRemoteCommands = false

    func play(url: URL) {
        do {
            try configureAudioSession()
        } catch {
            onEvent?(.failed(error.localizedDescription))
            return
        }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
        nowPlaying.nowPlayingInfo = NowPlayingInfoBuilder.build(title: AppConfig.stationTitle, isPlaying: true)
        onEvent?(.playing)
        registerRemoteCommands()
    }

    func pause() {
        player.pause()
        nowPlaying.nowPlayingInfo = NowPlayingInfoBuilder.build(title: AppConfig.stationTitle, isPlaying: false)
        onEvent?(.paused)
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    }

    private func registerRemoteCommands() {
        guard !didRegisterRemoteCommands else { return }
        didRegisterRemoteCommands = true
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.player.play()
            self?.nowPlaying.nowPlayingInfo = NowPlayingInfoBuilder.build(title: AppConfig.stationTitle, isPlaying: true)
            self?.onEvent?(.playing)
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.player.pause()
            self?.nowPlaying.nowPlayingInfo = NowPlayingInfoBuilder.build(title: AppConfig.stationTitle, isPlaying: false)
            self?.onEvent?(.paused)
            return .success
        }
    }
}
