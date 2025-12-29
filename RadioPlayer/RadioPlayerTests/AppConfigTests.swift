import XCTest
@testable import RadioPlayer

final class AppConfigTests: XCTestCase {
    func testStationTitleIsCNNNews() {
        XCTAssertEqual(AppConfig.stationTitle, "CNN News")
    }
}
