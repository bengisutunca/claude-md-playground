import Foundation
import Testing
@testable import TMDBApp

/// `HTTPClient` double: decodes a fixture or throws. Never touches the network.
private final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private var _endpoints: [Endpoint] = []
    let fixture: String?
    let error: Error?

    init(fixture: String? = nil, error: Error? = nil) {
        self.fixture = fixture
        self.error = error
    }

    var endpoints: [Endpoint] { lock.withLock { _endpoints } }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        lock.withLock { _endpoints.append(endpoint) }
        if let error { throw error }
        return try JSONDecoder.tmdb.decode(T.self, from: Fixture.data(fixture ?? ""))
    }
}

@Suite("TMDBMovieService")
struct MovieServiceTests {
    @Test func popularRequestsEndpointAndReturnsPage() async throws {
        let http = MockHTTPClient(fixture: "popular_page2")
        let page = try await TMDBMovieService(client: http).popular(page: 2)
        #expect(http.endpoints == [.popular(page: 2)])
        #expect(page.page == 2)
        #expect(!page.results.isEmpty)
    }

    @Test func searchRequestsEndpointAndReturnsResults() async throws {
        let http = MockHTTPClient(fixture: "search_inception")
        let page = try await TMDBMovieService(client: http).search(query: "inception", page: 1)
        #expect(http.endpoints == [.search(query: "inception", page: 1)])
        #expect(page.results.first?.title == "Inception")
    }

    @Test func searchEmptyReturnsNoResults() async throws {
        let http = MockHTTPClient(fixture: "search_empty")
        let page = try await TMDBMovieService(client: http).search(query: "zzzz", page: 1)
        #expect(page.results.isEmpty)
    }

    @Test func detailRequestsEndpointAndReturnsDetail() async throws {
        let http = MockHTTPClient(fixture: "movie_detail_27205")
        let detail = try await TMDBMovieService(client: http).detail(id: 27205)
        #expect(http.endpoints == [.movieDetail(id: 27205)])
        #expect(detail.id == 27205)
    }

    @Test func creditsRequestsEndpointAndReturnsCredits() async throws {
        let http = MockHTTPClient(fixture: "movie_credits_27205")
        let credits = try await TMDBMovieService(client: http).credits(id: 27205)
        #expect(http.endpoints == [.credits(movieID: 27205)])
        #expect(credits.id == 27205)
        #expect(!credits.cast.isEmpty)
    }

    @Test func propagatesClientError() async throws {
        let http = MockHTTPClient(error: APIError.httpStatus(code: 401, message: "Invalid API key"))
        let service = TMDBMovieService(client: http)
        await #expect(throws: APIError.self) { try await service.popular(page: 1) }
        await #expect(throws: APIError.self) { try await service.detail(id: 1) }
    }

    @Test func mockServiceRecordsCallsAndErrors() async throws {
        let mock = MockMovieService()
        _ = try await mock.popular(page: 1)
        _ = try await mock.search(query: "inception", page: 3)
        #expect(mock.calls == [.popular(page: 1), .search(query: "inception", page: 3)])
        mock.error = APIError.invalidResponse
        await #expect(throws: APIError.self) { try await mock.credits(id: 5) }
        #expect(mock.calls.last == .credits(id: 5))
    }
}
