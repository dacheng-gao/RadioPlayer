import XCTest
@testable import RadioPlayer

final class InfoPlistTests: XCTestCase {
    func testBackgroundAudioEnabled() {
        let modes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] ?? []
        XCTAssertTrue(modes.contains("audio"))
    }
}
