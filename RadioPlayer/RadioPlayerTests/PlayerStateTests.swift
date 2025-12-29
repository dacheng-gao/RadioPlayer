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
