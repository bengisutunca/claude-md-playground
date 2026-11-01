import Foundation

enum Endpoint: Equatable, Sendable {
    case popular(page: Int)
    case search(query: String, page: Int)
    case movieDetail(id: Int)
    case credits(movieID: Int)

    var path: String {
        switch self {
        case .popular: return "/movie/popular"
        case .search: return "/search/movie"
        case .movieDetail(let id): return "/movie/\(id)"
        case .credits(let id): return "/movie/\(id)/credits"
        }
    }

    func queryItems(apiKey: String) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]
        switch self {
        case .popular(let page):
            items.append(URLQueryItem(name: "page", value: String(page)))
        case .search(let query, let page):
            items.append(URLQueryItem(name: "query", value: query))
            items.append(URLQueryItem(name: "page", value: String(page)))
        case .movieDetail, .credits:
            break
        }
        return items
    }

    func urlRequest(configuration: APIConfiguration) throws -> URLRequest {
        guard var components = URLComponents(
            url: configuration.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.invalidResponse }
        components.queryItems = queryItems(apiKey: configuration.apiKey)
        guard let url = components.url else { throw APIError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
