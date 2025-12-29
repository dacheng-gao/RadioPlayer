import Foundation

struct MediaAPIClient {
    private let session: URLSessionProtocol
    private let endpoint = URL(string: "https://edition.cnn.com/audio/api/tunein/v1/media")!

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    func fetchStreamURL() async throws -> URL {
        let (data, _) = try await session.data(from: endpoint)
        let response = try JSONDecoder().decode(MediaResponse.self, from: data)
        return response.url
    }
}
