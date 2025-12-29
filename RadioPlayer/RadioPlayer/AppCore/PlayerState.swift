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
