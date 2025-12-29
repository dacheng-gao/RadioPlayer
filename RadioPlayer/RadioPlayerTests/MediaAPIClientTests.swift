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

        let session = MockURLSession(
            data: json,
            response: HTTPURLResponse(
                url: URL(string: "https://edition.cnn.com/audio/api/tunein/v1/media")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!,
            error: nil
        )
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
