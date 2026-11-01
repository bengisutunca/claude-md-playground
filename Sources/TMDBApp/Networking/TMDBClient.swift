import Foundation

struct TMDBClient: HTTPClient {
    private let configuration: APIConfiguration
    private let session: URLSession

    init(configuration: APIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let request = try endpoint.urlRequest(configuration: configuration)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder.tmdb.decode(TMDBErrorBody.self, from: data))?.statusMessage
            throw APIError.httpStatus(code: http.statusCode, message: message)
        }

        do {
            return try JSONDecoder.tmdb.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
