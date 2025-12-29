import XCTest
@testable import RadioPlayer

@MainActor
final class PlayerViewModelTests: XCTestCase {
    func testPlayFetchesURLAndStartsPlayback() async {
        let media = StubMediaProvider(url: URL(string: "https://tunein.cdnstream1.com/2868_96.mp3")!)
        let audio = FakeAudioPlayer()
        let viewModel = PlayerViewModel(mediaProvider: media, audioPlayer: audio)

        await viewModel.play()

        XCTAssertEqual(viewModel.state, .playing)
        XCTAssertEqual(audio.lastPlayedURL?.absoluteString, "https://tunein.cdnstream1.com/2868_96.mp3")
    }

    func testPauseSetsPausedState() async {
        let media = StubMediaProvider(url: URL(string: "https://tunein.cdnstream1.com/2868_96.mp3")!)
        let audio = FakeAudioPlayer()
        let viewModel = PlayerViewModel(mediaProvider: media, audioPlayer: audio)

        await viewModel.play()
        viewModel.pause()

        XCTAssertEqual(viewModel.state, .paused)
    }
}

final class StubMediaProvider: MediaStreamProviding {
    let url: URL
    init(url: URL) { self.url = url }
    func fetchStreamURL() async throws -> URL { url }
}

final class FakeAudioPlayer: AudioPlaying {
    var onEvent: ((AudioPlayerEvent) -> Void)?
    var lastPlayedURL: URL?

    func play(url: URL) {
        lastPlayedURL = url
        onEvent?(.playing)
    }

    func pause() {
        onEvent?(.paused)
    }
}
