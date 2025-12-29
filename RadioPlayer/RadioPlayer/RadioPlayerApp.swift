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
