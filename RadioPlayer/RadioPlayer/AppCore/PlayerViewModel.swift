import Foundation

protocol MediaStreamProviding {
    func fetchStreamURL() async throws -> URL
}

extension MediaAPIClient: MediaStreamProviding {}

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var state: PlayerState = .idle
    let title = AppConfig.stationTitle

    private let mediaProvider: MediaStreamProviding
    private let audioPlayer: AudioPlaying

    init(mediaProvider: MediaStreamProviding, audioPlayer: AudioPlaying) {
        self.mediaProvider = mediaProvider
        self.audioPlayer = audioPlayer

        self.audioPlayer.onEvent = { [weak self] event in
            switch event {
            case .playing:
                self?.state = .playing
            case .paused:
                self?.state = .paused
            case .failed(let message):
                self?.state = .error(message)
            }
        }
    }

    func play() async {
        state = .loading
        do {
            let url = try await mediaProvider.fetchStreamURL()
            audioPlayer.play(url: url)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func pause() {
        audioPlayer.pause()
    }
}
