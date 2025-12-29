import Foundation

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
