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
