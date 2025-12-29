# iOS CNN Radio Player Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a minimal iOS 16+ SwiftUI app that plays CNN News live stream with Play/Pause, background audio, and lock screen controls using the CNN media API to fetch the latest stream URL on each Play.

**Architecture:** Single-screen SwiftUI app with an AppCore state machine and an Audio layer. UI binds to a `PlayerViewModel` that fetches the stream URL on demand and drives an `AudioPlayerService` based on AVPlayer + MediaPlayer (Now Playing + Remote Commands).

**Tech Stack:** Swift 5.9, SwiftUI, AVFoundation, MediaPlayer, URLSession, XCTest, Xcode 16 (iOS 16+).

## Prerequisites

1. Create a new Xcode project at `RadioPlayer/` named `RadioPlayer` (SwiftUI App, iOS 16+, include Unit Tests).
2. Ensure the scheme is `RadioPlayer` and the unit test target is `RadioPlayerTests`.
3. Create target groups/folders: `AppCore`, `Audio`, `Network`, `UI` under `RadioPlayer/RadioPlayer/`.

### Task 1: Add player state model

**Files:**
- Create: `RadioPlayer/RadioPlayer/AppCore/PlayerState.swift`
- Create: `RadioPlayer/RadioPlayerTests/PlayerStateTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import RadioPlayer

final class PlayerStateTests: XCTestCase {
    func testStatusTextForAllStates() {
        XCTAssertEqual(PlayerState.idle.statusText, "Idle")
        XCTAssertEqual(PlayerState.loading.statusText, "Loading")
        XCTAssertEqual(PlayerState.playing.statusText, "Playing")
        XCTAssertEqual(PlayerState.paused.statusText, "Paused")
        XCTAssertEqual(PlayerState.error("x").statusText, "Error")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: FAIL with "Cannot find type 'PlayerState' in scope".

**Step 3: Write minimal implementation**

```swift
enum PlayerState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case error(String)

    var statusText: String {
        switch self {
        case .idle: return "Idle"
        case .loading: return "Loading"
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .error: return "Error"
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: PASS.

**Step 5: Commit**

```bash
git add RadioPlayer/RadioPlayer/AppCore/PlayerState.swift RadioPlayer/RadioPlayerTests/PlayerStateTests.swift
git commit -m "feat: add player state model"
```

### Task 2: Add media API client

**Files:**
- Create: `RadioPlayer/RadioPlayer/Network/MediaResponse.swift`
- Create: `RadioPlayer/RadioPlayer/Network/URLSessionProtocol.swift`
- Create: `RadioPlayer/RadioPlayer/Network/MediaAPIClient.swift`
- Create: `RadioPlayer/RadioPlayerTests/MediaAPIClientTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import RadioPlayer

final class MediaAPIClientTests: XCTestCase {
    func testFetchStreamURLReturnsDecodedURL() async throws {
        let json = #"""
        {
          "guideId": "s20407",
          "url": "https://tunein.cdnstream1.com/2868_96.mp3"
        }
        """#.data(using: .utf8)!

        let session = MockURLSession(data: json, response: HTTPURLResponse(url: URL(string: "https://edition.cnn.com/audio/api/tunein/v1/media")!, statusCode: 200, httpVersion: nil, headerFields: nil)!, error: nil)
        let client = MediaAPIClient(session: session)

        let url = try await client.fetchStreamURL()
        XCTAssertEqual(url.absoluteString, "https://tunein.cdnstream1.com/2868_96.mp3")
    }
}

final class MockURLSession: URLSessionProtocol {
    let data: Data
    let response: URLResponse
    let error: Error?

    init(data: Data, response: URLResponse, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error { throw error }
        return (data, response)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: FAIL with "Cannot find 'MediaAPIClient' in scope".

**Step 3: Write minimal implementation**

```swift
struct MediaResponse: Decodable {
    let guideId: String
    let url: URL
}

protocol URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

struct MediaAPIClient {
    private let session: URLSessionProtocol
    private let endpoint = URL(string: "https://edition.cnn.com/audio/api/tunein/v1/media")!

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    func fetchStreamURL() async throws -> URL {
        let (data, _) = try await session.data(from: endpoint)
        let response = try JSONDecoder().decode(MediaResponse.self, from: data)
        return response.url
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: PASS.

**Step 5: Commit**

```bash
git add RadioPlayer/RadioPlayer/Network/MediaResponse.swift \
  RadioPlayer/RadioPlayer/Network/URLSessionProtocol.swift \
  RadioPlayer/RadioPlayer/Network/MediaAPIClient.swift \
  RadioPlayer/RadioPlayerTests/MediaAPIClientTests.swift
git commit -m "feat: add media api client"
```

### Task 3: Add view model and dependency protocols

**Files:**
- Create: `RadioPlayer/RadioPlayer/AppCore/PlayerViewModel.swift`
- Create: `RadioPlayer/RadioPlayer/Audio/AudioPlayerProtocol.swift`
- Modify: `RadioPlayer/RadioPlayer/Network/MediaAPIClient.swift`
- Create: `RadioPlayer/RadioPlayerTests/PlayerViewModelTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import RadioPlayer

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
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: FAIL with "Cannot find 'PlayerViewModel' in scope".

**Step 3: Write minimal implementation**

```swift
protocol MediaStreamProviding {
    func fetchStreamURL() async throws -> URL
}

extension MediaAPIClient: MediaStreamProviding {}

enum AudioPlayerEvent: Equatable {
    case playing
    case paused
    case failed(String)
}

protocol AudioPlaying: AnyObject {
    var onEvent: ((AudioPlayerEvent) -> Void)? { get set }
    func play(url: URL)
    func pause()
}

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var state: PlayerState = .idle

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
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: PASS.

**Step 5: Commit**

```bash
git add RadioPlayer/RadioPlayer/AppCore/PlayerViewModel.swift \
  RadioPlayer/RadioPlayer/Audio/AudioPlayerProtocol.swift \
  RadioPlayer/RadioPlayer/Network/MediaAPIClient.swift \
  RadioPlayer/RadioPlayerTests/PlayerViewModelTests.swift
git commit -m "feat: add view model with audio protocols"
```

### Task 4: Add AVPlayer-backed audio service

**Files:**
- Create: `RadioPlayer/RadioPlayer/Audio/NowPlayingInfoBuilder.swift`
- Create: `RadioPlayer/RadioPlayer/Audio/AudioPlayerService.swift`
- Create: `RadioPlayer/RadioPlayerTests/NowPlayingInfoBuilderTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
import MediaPlayer
@testable import RadioPlayer

final class NowPlayingInfoBuilderTests: XCTestCase {
    func testBuildNowPlayingInfo() {
        let info = NowPlayingInfoBuilder.build(title: "CNN News", isPlaying: true)
        XCTAssertEqual(info[MPMediaItemPropertyTitle] as? String, "CNN News")
        XCTAssertEqual(info[MPNowPlayingInfoPropertyIsLiveStream] as? Bool, true)
        XCTAssertEqual(info[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 1.0)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: FAIL with "Cannot find 'NowPlayingInfoBuilder' in scope".

**Step 3: Write minimal implementation**

```swift
import MediaPlayer

enum NowPlayingInfoBuilder {
    static func build(title: String, isPlaying: Bool) -> [String: Any] {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = title
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        return info
    }
}
```

```swift
import AVFoundation
import MediaPlayer

final class AudioPlayerService: NSObject, AudioPlaying {
    var onEvent: ((AudioPlayerEvent) -> Void)?

    private let player = AVPlayer()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private let nowPlaying = MPNowPlayingInfoCenter.default()

    func play(url: URL) {
        configureAudioSession()
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
        nowPlaying.nowPlayingInfo = NowPlayingInfoBuilder.build(title: "CNN News", isPlaying: true)
        onEvent?(.playing)
        registerRemoteCommands()
    }

    func pause() {
        player.pause()
        nowPlaying.nowPlayingInfo = NowPlayingInfoBuilder.build(title: "CNN News", isPlaying: false)
        onEvent?(.paused)
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    private func registerRemoteCommands() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.player.play()
            self?.nowPlaying.nowPlayingInfo = NowPlayingInfoBuilder.build(title: "CNN News", isPlaying: true)
            self?.onEvent?(.playing)
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.player.pause()
            self?.nowPlaying.nowPlayingInfo = NowPlayingInfoBuilder.build(title: "CNN News", isPlaying: false)
            self?.onEvent?(.paused)
            return .success
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: PASS.

**Step 5: Commit**

```bash
git add RadioPlayer/RadioPlayer/Audio/NowPlayingInfoBuilder.swift \
  RadioPlayer/RadioPlayer/Audio/AudioPlayerService.swift \
  RadioPlayer/RadioPlayerTests/NowPlayingInfoBuilderTests.swift
git commit -m "feat: add avplayer audio service"
```

### Task 5: Add app config and wire UI

**Files:**
- Create: `RadioPlayer/RadioPlayer/AppCore/AppConfig.swift`
- Modify: `RadioPlayer/RadioPlayer/AppCore/PlayerViewModel.swift`
- Modify: `RadioPlayer/RadioPlayer/ContentView.swift`
- Modify: `RadioPlayer/RadioPlayer/RadioPlayerApp.swift`
- Create: `RadioPlayer/RadioPlayerTests/AppConfigTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import RadioPlayer

final class AppConfigTests: XCTestCase {
    func testStationTitleIsCNNNews() {
        XCTAssertEqual(AppConfig.stationTitle, "CNN News")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: FAIL with "Cannot find 'AppConfig' in scope".

**Step 3: Write minimal implementation**

```swift
enum AppConfig {
    static let stationTitle = "CNN News"
}
```

```swift
@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var state: PlayerState = .idle
    let title = AppConfig.stationTitle

    // existing implementation
}
```

```swift
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text(viewModel.title)
                .font(.title)

            Text(viewModel.state.statusText)
                .font(.subheadline)

            Button(action: {
                if viewModel.state == .playing {
                    viewModel.pause()
                } else {
                    Task { await viewModel.play() }
                }
            }) {
                Text(viewModel.state == .playing ? "Pause" : "Play")
                    .font(.headline)
            }
        }
        .padding()
    }
}
```

```swift
import SwiftUI

@main
struct RadioPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: PlayerViewModel(
                    mediaProvider: MediaAPIClient(),
                    audioPlayer: AudioPlayerService()
                )
            )
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: PASS.

**Step 5: Commit**

```bash
git add RadioPlayer/RadioPlayer/AppCore/AppConfig.swift \
  RadioPlayer/RadioPlayer/AppCore/PlayerViewModel.swift \
  RadioPlayer/RadioPlayer/ContentView.swift \
  RadioPlayer/RadioPlayer/RadioPlayerApp.swift \
  RadioPlayer/RadioPlayerTests/AppConfigTests.swift
git commit -m "feat: wire ui and config"
```

### Task 6: Enable background audio in Info.plist

**Files:**
- Modify: `RadioPlayer/RadioPlayer/Info.plist`
- Create: `RadioPlayer/RadioPlayerTests/InfoPlistTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import RadioPlayer

final class InfoPlistTests: XCTestCase {
    func testBackgroundAudioEnabled() {
        let modes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] ?? []
        XCTAssertTrue(modes.contains("audio"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: FAIL with "XCTAssertTrue failed".

**Step 3: Write minimal implementation**

Add to `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

Also enable Background Modes > Audio in the Xcode target settings.

**Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme RadioPlayer -destination 'platform=iOS Simulator,name=iPhone 15' test`
Expected: PASS.

**Step 5: Commit**

```bash
git add RadioPlayer/RadioPlayer/Info.plist RadioPlayer/RadioPlayerTests/InfoPlistTests.swift
git commit -m "feat: enable background audio"
```

## Manual Verification Checklist

- Build & run on a physical iPhone.
- Tap Play, confirm audio starts.
- Lock screen: verify Play/Pause controls appear and work.
- Background the app: audio continues.
- Tap Pause: audio stops and state text updates.

