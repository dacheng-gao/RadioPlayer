import Foundation

struct MediaAPIClient {
    private let session: URLSessionProtocol
    private let endpoint = URL(string: "https://edition.cnn.com/audio/api/tunein/v1/media")!
    private let guideId: String

    init(session: URLSessionProtocol = URLSession.shared, guideId: String = AppConfig.stationGuideId) {
        self.session = session
        self.guideId = guideId
    }

    func fetchStreamURL() async throws -> URL {
        let request = try buildRequest()
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(MediaResponse.self, from: data)
        return response.url
    }

    private func buildRequest() throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = MediaRequest(
            guideId: guideId,
            serialNumber: UUID().uuidString,
            listenId: Int64(Date().timeIntervalSince1970 * 1000)
        )
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }
}

private struct MediaRequest: Encodable {
    let guideId: String
    let serialNumber: String
    let listenId: Int64
}
