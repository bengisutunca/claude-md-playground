import Foundation

enum Endpoint: Equatable, Sendable {
    case popular(page: Int)
    case search(query: String, page: Int)
    case movieDetail(id: Int)
    case credits(movieID: Int)

    var path: String {
        switch self {
        case .popular: "/movie/popular"
        case .search: "/search/movie"
        case .movieDetail(let id): "/movie/\(id)"
        case .credits(let id): "/movie/\(id)/credits"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .popular(let page):
            [URLQueryItem(name: "page", value: String(page))]
        case .search(let query, let page):
            [URLQueryItem(name: "query", value: query), URLQueryItem(name: "page", value: String(page))]
        case .movieDetail, .credits:
            []
        }
    }

    /// Builds a GET request with `api_key` and `language=en-US` appended.
    func urlRequest(configuration: APIConfiguration) throws -> URLRequest {
        var components = URLComponents(url: configuration.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems + [
            URLQueryItem(name: "api_key", value: configuration.apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]
        guard let url = components?.url else { throw APIError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
