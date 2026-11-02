import Foundation
import Testing
@testable import TMDBApp

// Hidden acceptance test: copied in by the benchmark harness after the session ends.
// The agent never sees this file. Self-contained: it does not use any test helper the agent wrote.

private struct AccMissingFixture: Error { let name: String }

private func accData(_ name: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
        throw AccMissingFixture(name: name)
    }
    return try Data(contentsOf: url)
}

private final class AccHTTPClient: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private var sent: [Endpoint] = []

    var endpoints: [Endpoint] {
        lock.lock(); defer { lock.unlock() }
        return sent
    }

    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        lock.lock(); sent.append(endpoint); lock.unlock()
        let name: String
        switch endpoint {
        case .popular: name = "popular_page1"
        case .search: name = "search_inception"
        case .movieDetail: name = "movie_detail_27205"
        case .credits: name = "movie_credits_27205"
        default: name = "popular_page1"
        }
        return try JSONDecoder.tmdb.decode(T.self, from: accData(name))
    }
}

@Suite("Acceptance 03: service layer")
struct Acceptance03Tests {
    @Test func popularUsesPopularEndpoint() async throws {
        let http = AccHTTPClient()
        let page = try await TMDBMovieService(client: http).popular(page: 2)
        #expect(page.results.count == 5)
        #expect(http.endpoints == [.popular(page: 2)])
    }

    @Test func searchUsesSearchEndpoint() async throws {
        let http = AccHTTPClient()
        let page = try await TMDBMovieService(client: http).search(query: "Inception", page: 1)
        #expect(page.results.map(\.id) == [27205])
        #expect(http.endpoints == [.search(query: "Inception", page: 1)])
    }

    @Test func detailAndCredits() async throws {
        let http = AccHTTPClient()
        let service = TMDBMovieService(client: http)
        let detail = try await service.detail(id: 27205)
        let credits = try await service.credits(id: 27205)
        #expect(detail.title == "Inception")
        #expect(credits.cast.count == 4)
        #expect(http.endpoints == [.movieDetail(id: 27205), .credits(movieID: 27205)])
    }

    @Test func serviceConformsToProtocol() async throws {
        let service: any MovieService = TMDBMovieService(client: AccHTTPClient())
        let page = try await service.popular(page: 1)
        #expect(page.page == 1)
    }

    @Test func imageURLs() {
        let builder = ImageURLBuilder()
        #expect(builder.url(path: "/inception.jpg", size: .w342)?.absoluteString
                == "https://image.tmdb.org/t/p/w342/inception.jpg")
        #expect(builder.url(path: "/inception.jpg", size: .original)?.absoluteString
                == "https://image.tmdb.org/t/p/original/inception.jpg")
        #expect(builder.url(path: "/a.jpg", size: .w185)?.absoluteString == "https://image.tmdb.org/t/p/w185/a.jpg")
        #expect(builder.url(path: "/a.jpg", size: .w780)?.absoluteString == "https://image.tmdb.org/t/p/w780/a.jpg")
    }

    @Test func missingImagePathGivesNil() {
        let builder = ImageURLBuilder()
        #expect(builder.url(path: nil, size: .w342) == nil)
        #expect(builder.url(path: "", size: .w342) == nil)
    }

    @Test func sizeRawValues() {
        #expect(ImageURLBuilder.Size.w185.rawValue == "w185")
        #expect(ImageURLBuilder.Size.original.rawValue == "original")
    }
}
