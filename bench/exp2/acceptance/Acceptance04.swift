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

@MainActor
@Suite("Acceptance 04: movie list")
struct Acceptance04Tests {
    private func service() throws -> AccMovieService {
        let s = AccMovieService()
        s.pages = [1: try accPage("popular_page1"), 2: try accPage("popular_page2")]
        return s
    }

    @Test func firstLoad() async throws {
        let vm = MovieListViewModel(service: try service())
        await vm.load()
        #expect(accLoadedIDs(vm.state) == [27205, 157336, 155, 278, 550])
    }

    @Test func lastItemLoadsNextPage() async throws {
        let s = try service()
        let vm = MovieListViewModel(service: s)
        await vm.load()
        let last = try #require(accLoadedMovies(vm.state).last)
        await vm.loadNextPageIfNeeded(currentItem: last)
        #expect(accLoadedIDs(vm.state) == [27205, 157336, 155, 278, 550, 129, 496243])
        #expect(s.popularCalls == [1, 2])
    }

    @Test func stopsAtTotalPages() async throws {
        let s = try service()
        let vm = MovieListViewModel(service: s)
        await vm.load()
        let last1 = try #require(accLoadedMovies(vm.state).last)
        await vm.loadNextPageIfNeeded(currentItem: last1)
        let last2 = try #require(accLoadedMovies(vm.state).last)
        await vm.loadNextPageIfNeeded(currentItem: last2)
        #expect(s.popularCalls == [1, 2])
        #expect(accLoadedIDs(vm.state)?.count == 7)
    }

    @Test func errorGivesFailedState() async throws {
        let s = try service()
        s.popularError = URLError(.notConnectedToInternet)
        let vm = MovieListViewModel(service: s)
        await vm.load()
        guard case .failed(let message) = vm.state else {
            Issue.record("expected .failed, got \(vm.state)")
            return
        }
        #expect(message.isEmpty == false)
    }

    @Test func emptyPageGivesEmptyState() async throws {
        let s = AccMovieService()
        s.pages = [1: try accPage("search_empty")]
        let vm = MovieListViewModel(service: s)
        await vm.load()
        guard case .empty = vm.state else {
            Issue.record("expected .empty, got \(vm.state)")
            return
        }
    }

    @Test func refreshStartsFromFirstPage() async throws {
        let s = try service()
        let vm = MovieListViewModel(service: s)
        await vm.load()
        let last = try #require(accLoadedMovies(vm.state).last)
        await vm.loadNextPageIfNeeded(currentItem: last)
        await vm.refresh()
        #expect(accLoadedIDs(vm.state) == [27205, 157336, 155, 278, 550])
        #expect(s.popularCalls == [1, 2, 1])
    }
}
