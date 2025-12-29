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
