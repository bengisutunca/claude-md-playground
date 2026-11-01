import Foundation
import Testing
@testable import TMDBApp

@Suite("Networking", .serialized)
struct NetworkingTests {
    let configuration = APIConfiguration(apiKey: "test-key")

    private func client(status: Int = 200, body: Data) -> TMDBClient {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }
        return TMDBClient(configuration: configuration, session: MockURLProtocol.makeSession())
    }

    private func items(_ endpoint: Endpoint) throws -> [String: String] {
        let request = try endpoint.urlRequest(configuration: configuration)
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
    }

    @Test func successDecodesPopular() async throws {
        let client = client(body: try Fixture.data("popular_page1"))
        let page = try await client.send(.popular(page: 1), as: PagedResponse<Movie>.self)
        #expect(page.page == 1)
        #expect(page.results.first?.title == "Inception")
    }

    @Test func unauthorizedMapsToHTTPStatus() async throws {
        let client = client(status: 401, body: try Fixture.data("error_401"))
        do {
            _ = try await client.send(.popular(page: 1), as: PagedResponse<Movie>.self)
            Issue.record("expected throw")
        } catch let APIError.httpStatus(code, message) {
            #expect(code == 401)
            #expect(message == "Invalid API key: You must be granted a valid key.")
        }
    }

    @Test func malformedBodyMapsToDecoding() async throws {
        let client = client(body: try Fixture.data("error_401"))
        do {
            _ = try await client.send(.popular(page: 1), as: PagedResponse<Movie>.self)
            Issue.record("expected throw")
        } catch APIError.decoding {
        }
    }

    @Test func transportFailureMapsToTransport() async throws {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        let client = TMDBClient(configuration: configuration, session: MockURLProtocol.makeSession())
        do {
            _ = try await client.send(.popular(page: 1), as: PagedResponse<Movie>.self)
            Issue.record("expected throw")
        } catch APIError.transport {
        }
    }

    @Test func popularQuery() throws {
        let request = try Endpoint.popular(page: 2).urlRequest(configuration: configuration)
        #expect(request.url?.path == "/3/movie/popular")
        #expect(try items(.popular(page: 2)) == ["page": "2", "api_key": "test-key", "language": "en-US"])
    }

    @Test func searchQuery() throws {
        let request = try Endpoint.search(query: "star wars & co", page: 3).urlRequest(configuration: configuration)
        #expect(request.url?.path == "/3/search/movie")
        #expect(try items(.search(query: "star wars & co", page: 3))
            == ["query": "star wars & co", "page": "3", "api_key": "test-key", "language": "en-US"])
    }

    @Test func movieDetailQuery() throws {
        let request = try Endpoint.movieDetail(id: 27205).urlRequest(configuration: configuration)
        #expect(request.url?.path == "/3/movie/27205")
        #expect(try items(.movieDetail(id: 27205)) == ["api_key": "test-key", "language": "en-US"])
    }

    @Test func creditsQuery() throws {
        let request = try Endpoint.credits(movieID: 27205).urlRequest(configuration: configuration)
        #expect(request.url?.path == "/3/movie/27205/credits")
        #expect(try items(.credits(movieID: 27205)) == ["api_key": "test-key", "language": "en-US"])
    }

    @Test func configurationPrefersEnvironmentAndThrowsWhenMissing() throws {
        let bundle = Bundle(for: MockURLProtocol.self)
        let config = try APIConfiguration.load(environment: ["TMDB_API_KEY": "abc"], bundle: bundle)
        #expect(config.apiKey == "abc")
        #expect(throws: APIError.self) {
            try APIConfiguration.load(environment: [:], bundle: bundle)
        }
    }
}
