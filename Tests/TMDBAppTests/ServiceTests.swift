import Foundation
import Testing
@testable import TMDBApp

/// `HTTPClient` that never touches the network: decodes a fixture and records endpoints.
private final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [Endpoint] = []
    var endpoints: [Endpoint] { lock.withLock { recorded } }

    let fixture: String?
    let error: Error?

    init(fixture: String? = nil, error: Error? = nil) {
        self.fixture = fixture
        self.error = error
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        lock.withLock { recorded.append(endpoint) }
        if let error { throw error }
        return try JSONDecoder.tmdb.decode(T.self, from: Fixture.data(fixture!))
    }
}

@Suite("TMDBMovieService")
struct TMDBMovieServiceTests {
    @Test func popularRequestsEndpointAndDecodes() async throws {
        let client = MockHTTPClient(fixture: "popular_page2")
        let page = try await TMDBMovieService(client: client).popular(page: 2)
        #expect(client.endpoints == [.popular(page: 2)])
        #expect(page.page == 2)
        #expect(!page.results.isEmpty)
    }

    @Test func searchRequestsEndpointAndDecodes() async throws {
        let client = MockHTTPClient(fixture: "search_inception")
        let page = try await TMDBMovieService(client: client).search(query: "inception", page: 1)
        #expect(client.endpoints == [.search(query: "inception", page: 1)])
        #expect(!page.results.isEmpty)
    }

    @Test func searchEmptyResults() async throws {
        let client = MockHTTPClient(fixture: "search_empty")
        let page = try await TMDBMovieService(client: client).search(query: "zzz", page: 1)
        #expect(page.results.isEmpty)
    }

    @Test func detailRequestsEndpointAndDecodes() async throws {
        let client = MockHTTPClient(fixture: "movie_detail_27205")
        let detail = try await TMDBMovieService(client: client).detail(id: 27205)
        #expect(client.endpoints == [.movieDetail(id: 27205)])
        #expect(detail.id == 27205)
    }

    @Test func creditsRequestsEndpointAndDecodes() async throws {
        let client = MockHTTPClient(fixture: "movie_credits_27205")
        let credits = try await TMDBMovieService(client: client).credits(id: 27205)
        #expect(client.endpoints == [.credits(movieID: 27205)])
        #expect(credits.id == 27205)
    }

    @Test func propagatesClientError() async throws {
        let client = MockHTTPClient(error: APIError.httpStatus(code: 401, message: "nope"))
        do {
            _ = try await TMDBMovieService(client: client).popular(page: 1)
            Issue.record("expected error")
        } catch APIError.httpStatus(let code, _) {
            #expect(code == 401)
        }
    }
}

@Suite("MockMovieService")
struct MockMovieServiceTests {
    @Test func returnsFixturesAndRecordsCalls() async throws {
        let mock = MockMovieService()
        let page = try await mock.popular(page: 1)
        _ = try await mock.detail(id: 27205)
        #expect(!page.results.isEmpty)
        #expect(await mock.calls == [.popular(page: 1), .detail(id: 27205)])
    }

    @Test func throwsConfiguredError() async {
        let mock = MockMovieService(error: APIError.invalidResponse)
        do {
            _ = try await mock.credits(id: 1)
            Issue.record("expected error")
        } catch {
            #expect(error is APIError)
        }
    }
}

@Suite("ImageURLBuilder")
struct ImageURLBuilderTests {
    let builder = ImageURLBuilder()

    @Test func buildsURLForEachSize() {
        for size in ImageURLBuilder.Size.allCases {
            let expected = "https://image.tmdb.org/t/p/" + size.rawValue + "/abc.jpg"
            #expect(builder.url(path: "/abc.jpg", size: size)?.absoluteString == expected)
        }
    }

    @Test func nilPathReturnsNil() {
        #expect(builder.url(path: nil, size: .w185) == nil)
    }

    @Test func emptyPathReturnsNil() {
        #expect(builder.url(path: "", size: .w342) == nil)
    }

    @Test func pathWithoutLeadingSlash() {
        #expect(builder.url(path: "abc.jpg", size: .original)?.absoluteString
                == "https://image.tmdb.org/t/p/original/abc.jpg")
    }

    @Test func customBaseURL() {
        let b = ImageURLBuilder(baseURL: URL(string: "https://example.test/img")!)
        #expect(b.url(path: "/x.png", size: .w780)?.absoluteString == "https://example.test/img/w780/x.png")
    }
}
