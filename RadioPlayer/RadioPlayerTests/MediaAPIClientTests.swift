import Foundation
import XCTest
@testable import RadioPlayer

final class MediaAPIClientTests: XCTestCase {
    func testFetchStreamURLUsesPOSTWithGuideId() async throws {
        let json = #"""
        {
          "guideId": "s20407",
          "url": "https://tunein.cdnstream1.com/2868_96.mp3"
        }
        """#.data(using: .utf8)!
        let session = makeSession(responseData: json)
        defer { CapturingURLProtocol.reset() }

        let client = MediaAPIClient(session: session)
        let url = try await client.fetchStreamURL()

        XCTAssertEqual(url.absoluteString, "https://tunein.cdnstream1.com/2868_96.mp3")

        let request = try XCTUnwrap(CapturingURLProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://edition.cnn.com/audio/api/tunein/v1/media")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try bodyData(from: request)
        let jsonObject = try JSONSerialization.jsonObject(with: body, options: []) as? [String: Any]
        XCTAssertEqual(jsonObject?["guideId"] as? String, "s20407")
        XCTAssertNotNil(jsonObject?["serialNumber"] as? String)
        XCTAssertNotNil(jsonObject?["listenId"])
    }

    private func makeSession(responseData: Data) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [CapturingURLProtocol.self]
        CapturingURLProtocol.responseData = responseData
        return URLSession(configuration: configuration)
    }

    private func bodyData(from request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            return Data()
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 {
                throw stream.streamError ?? NSError(domain: "BodyStreamError", code: -1)
            }
            if count == 0 {
                break
            }
            data.append(buffer, count: count)
        }
        return data
    }
}

final class CapturingURLProtocol: URLProtocol {
    static var lastRequest: URLRequest?
    static var responseData = Data()
    static var statusCode = 200

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lastRequest = request
        guard let url = request.url else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        lastRequest = nil
        responseData = Data()
        statusCode = 200
    }
}
