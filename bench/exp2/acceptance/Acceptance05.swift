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

private final class AccSleepRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Duration] = []
    var durations: [Duration] { lock.lock(); defer { lock.unlock() }; return values }
    func record(_ d: Duration) { lock.lock(); values.append(d); lock.unlock() }
}

@MainActor
@Suite("Acceptance 05: search")
struct Acceptance05Tests {
    private func makeVM(_ s: AccMovieService) -> SearchViewModel {
        SearchViewModel(service: s, sleep: { _ in })
    }

    @Test func shortQueryDoesNotSearch() async throws {
        let s = AccMovieService()
        s.searchResult = try accPage("search_inception")
        let vm = makeVM(s)
        vm.query = "a"
        await vm.waitForSearch()
        vm.query = " b "
        await vm.waitForSearch()
        #expect(s.searchCalls.isEmpty)
        guard case .idle = vm.state else {
            Issue.record("expected .idle, got \(vm.state)")
            return
        }
    }

    @Test func rapidTypingSearchesOnce() async throws {
        let s = AccMovieService()
        s.searchResult = try accPage("search_inception")
        let vm = makeVM(s)
        vm.query = "In"
        vm.query = "Inc"
        vm.query = "Ince"
        vm.query = "Incep"
        await vm.waitForSearch()
        #expect(s.searchCalls == ["Incep"])
    }

    @Test func resultsAreLoaded() async throws {
        let s = AccMovieService()
        s.searchResult = try accPage("search_inception")
        let vm = makeVM(s)
        vm.query = "Inception"
        await vm.waitForSearch()
        #expect(accLoadedIDs(vm.state) == [27205])
    }

    @Test func noResultsGivesEmpty() async throws {
        let s = AccMovieService()
        s.searchResult = try accPage("search_empty")
        let vm = makeVM(s)
        vm.query = "zzzz"
        await vm.waitForSearch()
        guard case .empty = vm.state else {
            Issue.record("expected .empty, got \(vm.state)")
            return
        }
    }

    @Test func errorGivesFailed() async throws {
        let s = AccMovieService()
        s.searchError = URLError(.timedOut)
        let vm = makeVM(s)
        vm.query = "Inception"
        await vm.waitForSearch()
        guard case .failed(let message) = vm.state else {
            Issue.record("expected .failed, got \(vm.state)")
            return
        }
        #expect(message.isEmpty == false)
    }

    @Test func debounceUsesInjectedSleep() async throws {
        let s = AccMovieService()
        s.searchResult = try accPage("search_inception")
        let recorder = AccSleepRecorder()
        let vm = SearchViewModel(service: s, sleep: { recorder.record($0) })
        vm.query = "Inception"
        await vm.waitForSearch()
        #expect(recorder.durations == [.milliseconds(300)])
        #expect(s.searchCalls == ["Inception"])
    }
}
