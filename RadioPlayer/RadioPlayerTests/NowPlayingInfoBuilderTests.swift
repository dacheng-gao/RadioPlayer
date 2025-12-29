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
