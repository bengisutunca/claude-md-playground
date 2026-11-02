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

private final class AccMovieService: MovieService, @unchecked Sendable {
    private let lock = NSLock()
    private var _popularCalls: [Int] = []
    private var _searchCalls: [String] = []
    var pages: [Int: PagedResponse<Movie>] = [:]
    var searchResult: PagedResponse<Movie>?
    var detailResult: MovieDetail?
    var creditsResult: Credits?
    var popularError: Error?
    var searchError: Error?
    var detailError: Error?
    var creditsError: Error?

    var popularCalls: [Int] { lock.lock(); defer { lock.unlock() }; return _popularCalls }
    var searchCalls: [String] { lock.lock(); defer { lock.unlock() }; return _searchCalls }

    func popular(page: Int) async throws -> PagedResponse<Movie> {
        lock.lock(); _popularCalls.append(page); lock.unlock()
        if let popularError { throw popularError }
        guard let result = pages[page] else { throw URLError(.fileDoesNotExist) }
        return result
    }

    func search(query: String, page: Int) async throws -> PagedResponse<Movie> {
        lock.lock(); _searchCalls.append(query); lock.unlock()
        if let searchError { throw searchError }
        guard let searchResult else { throw URLError(.fileDoesNotExist) }
        return searchResult
    }

    func detail(id: Int) async throws -> MovieDetail {
        if let detailError { throw detailError }
        guard let detailResult else { throw URLError(.fileDoesNotExist) }
        return detailResult
    }

    func credits(id: Int) async throws -> Credits {
        if let creditsError { throw creditsError }
        guard let creditsResult else { throw URLError(.fileDoesNotExist) }
        return creditsResult
    }
}

private func accPage(_ name: String) throws -> PagedResponse<Movie> {
    try JSONDecoder.tmdb.decode(PagedResponse<Movie>.self, from: accData(name))
}

private func accLoadedIDs(_ state: ViewState<[Movie]>) -> [Int]? {
    if case .loaded(let movies) = state { return movies.map(\.id) }
    return nil
}

private func accLoadedMovies(_ state: ViewState<[Movie]>) -> [Movie] {
    if case .loaded(let movies) = state { return movies }
    return []
}

private func accCredits(castOrders: [Int]) throws -> Credits {
    let cast = castOrders.map { o in
        #"{"id": \#(1000 + o), "name": "Actor \#(o)", "character": "Role \#(o)", "order": \#(o), "profile_path": null}"#
    }.joined(separator: ",")
    let json = #"{"id": 27205, "cast": [\#(cast)], "crew": [{"id": 525, "name": "Christopher Nolan", "job": "Director", "department": "Directing", "profile_path": null}, {"id": 9, "name": "Hans Zimmer", "job": "Original Music Composer", "department": "Sound", "profile_path": null}]}"#
    return try JSONDecoder.tmdb.decode(Credits.self, from: Data(json.utf8))
}

@MainActor
@Suite("Acceptance 06: detail")
struct Acceptance06Tests {
    private func service() throws -> AccMovieService {
        let s = AccMovieService()
        s.detailResult = try JSONDecoder.tmdb.decode(MovieDetail.self, from: accData("movie_detail_27205"))
        s.creditsResult = try JSONDecoder.tmdb.decode(Credits.self, from: accData("movie_credits_27205"))
        return s
    }

    @Test func loadsDetailAndCredits() async throws {
        let vm = MovieDetailViewModel(movieID: 27205, service: try service())
        await vm.load()
        guard case .loaded(let content) = vm.state else {
            Issue.record("expected .loaded, got \(vm.state)")
            return
        }
        #expect(content.detail.title == "Inception")
        #expect(content.cast.map(\.name) == ["Leonardo DiCaprio", "Joseph Gordon-Levitt", "Elliot Page", "Tom Hardy"])
        #expect(content.directors.map(\.name) == ["Christopher Nolan"])
        #expect(content.genresText == "Action, Science Fiction, Adventure")
        #expect(content.runtimeText == "2h 28m")
    }

    @Test func castIsTopTenByOrder() async throws {
        let s = try service()
        s.creditsResult = try accCredits(castOrders: [11, 3, 0, 7, 1, 10, 2, 9, 4, 8, 6, 5])
        let vm = MovieDetailViewModel(movieID: 27205, service: s)
        await vm.load()
        guard case .loaded(let content) = vm.state else {
            Issue.record("expected .loaded, got \(vm.state)")
            return
        }
        #expect(content.cast.map(\.name) == (0..<10).map { "Actor \($0)" })
        #expect(content.directors.map(\.name) == ["Christopher Nolan"])
    }

    @Test func detailFailureGivesFailed() async throws {
        let s = try service()
        s.detailError = URLError(.timedOut)
        let vm = MovieDetailViewModel(movieID: 27205, service: s)
        await vm.load()
        guard case .failed = vm.state else {
            Issue.record("expected .failed, got \(vm.state)")
            return
        }
    }

    @Test func creditsFailureGivesFailed() async throws {
        let s = try service()
        s.creditsError = URLError(.timedOut)
        let vm = MovieDetailViewModel(movieID: 27205, service: s)
        await vm.load()
        guard case .failed = vm.state else {
            Issue.record("expected .failed, got \(vm.state)")
            return
        }
    }

    @Test(arguments: [(148, "2h 28m"), (120, "2h"), (45, "45m"), (0, "0m"), (61, "1h 1m"), (60, "1h")])
    func runtimeFormatting(minutes: Int, expected: String) {
        #expect(MovieDetailContent.formatRuntime(minutes: minutes) == expected)
    }
}
