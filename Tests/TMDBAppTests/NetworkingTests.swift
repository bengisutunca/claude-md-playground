import Foundation
import Testing
@testable import TMDBApp

@Suite("Networking", .serialized)
struct NetworkingTests {
    let config = APIConfiguration(apiKey: "test-key", baseURL: URL(string: "https://example.test/3")!)

    private func client(status: Int = 200, body: Data) -> TMDBClient {
        MockURLProtocol.handler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!, body)
        }
        return TMDBClient(session: MockURLProtocol.session(), configuration: config)
    }

    @Test func successDecodes() async throws {
        let c = client(body: try Fixture.data("popular_page1"))
        let page = try await c.send(.popular(page: 1), as: PagedResponse<Movie>.self)
        #expect(page.page == 1)
        #expect(page.results.count == 5)
    }

    @Test func unauthorizedMapsToHTTPStatus() async throws {
        let c = client(status: 401, body: try Fixture.data("error_401"))
        do {
            _ = try await c.send(.popular(page: 1), as: PagedResponse<Movie>.self)
            Issue.record("expected error")
        } catch APIError.httpStatus(let code, let message) {
            #expect(code == 401)
            #expect(message == "Invalid API key: You must be granted a valid key.")
        }
    }

    @Test func decodingFailure() async throws {
        // A paged body is not a MovieDetail.
        let c = client(body: try Fixture.data("popular_page1"))
        do {
            _ = try await c.send(.popular(page: 1), as: MovieDetail.self)
            Issue.record("expected error")
        } catch APIError.decoding {
        }
    }

    @Test func transportError() async throws {
        MockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        let c = TMDBClient(session: MockURLProtocol.session(), configuration: config)
        do {
            _ = try await c.send(.popular(page: 1), as: PagedResponse<Movie>.self)
            Issue.record("expected error")
        } catch APIError.transport {
        }
    }

    @Test func apiKeyResolution() throws {
        let empty = Bundle(for: MockURLProtocol.self)
        #expect(throws: APIError.self) {
            try APIConfiguration.load(environment: [:], bundle: empty)
        }
        #expect(try APIConfiguration.load(environment: ["TMDB_API_KEY": "abc"]).apiKey == "abc")
    }

    private func parts(_ e: Endpoint) throws -> (path: String, items: [String: String]) {
        let url = try #require(try e.urlRequest(configuration: config).url)
        let comps = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let dict = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        return (comps.path, dict)
    }

    @Test func popularQuery() throws {
        let r = try parts(.popular(page: 2))
        #expect(r.path == "/3/movie/popular")
        #expect(r.items == ["api_key": "test-key", "language": "en-US", "page": "2"])
    }

    @Test func searchQuery() throws {
        let r = try parts(.search(query: "the matrix & co", page: 3))
        #expect(r.path == "/3/search/movie")
        #expect(r.items == ["api_key": "test-key", "language": "en-US", "query": "the matrix & co", "page": "3"])
    }

    @Test func detailQuery() throws {
        let r = try parts(.movieDetail(id: 27205))
        #expect(r.path == "/3/movie/27205")
        #expect(r.items == ["api_key": "test-key", "language": "en-US"])
    }

    @Test func creditsQuery() throws {
        let r = try parts(.credits(movieID: 27205))
        #expect(r.path == "/3/movie/27205/credits")
        #expect(r.items == ["api_key": "test-key", "language": "en-US"])
    }
}
