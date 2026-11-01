import Foundation

protocol HTTPClient: Sendable {
    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

struct TMDBClient: HTTPClient {
    private let session: URLSession
    private let configuration: APIConfiguration?

    /// - Parameter configuration: when nil, it is resolved on each send
    ///   (environment / Info.plist), throwing `APIError.missingAPIKey` if absent.
    init(session: URLSession = .shared, configuration: APIConfiguration? = nil) {
        self.session = session
        self.configuration = configuration
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let config = try configuration ?? APIConfiguration.load()
        let request = try endpoint.urlRequest(configuration: config)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = try? JSONDecoder.tmdb.decode(TMDBErrorBody.self, from: data).statusMessage
            throw APIError.httpStatus(code: http.statusCode, message: message)
        }

        do {
            return try JSONDecoder.tmdb.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
