import Foundation
import Testing
@testable import TMDBApp

@MainActor
@Suite("MovieListViewModel")
struct MovieListViewModelTests {
    private func loadedMovies(_ vm: MovieListViewModel) -> [Movie] {
        if case .loaded(let movies) = vm.state { return movies }
        return []
    }

    @Test func firstLoad() async throws {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        #expect(vm.state == .idle)
        await vm.load()
        #expect(loadedMovies(vm).count == 5)
        #expect(loadedMovies(vm).first?.id == 27205)
        #expect(await service.calls == [.popular(page: 1)])
    }

    @Test func paginationAppendsPage2AndStopsAtEnd() async throws {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        await vm.load()
        let last = try #require(loadedMovies(vm).last)
        await vm.loadNextPageIfNeeded(currentItem: last)
        #expect(loadedMovies(vm).count == 7)
        #expect(!vm.canLoadMore)

        let newLast = try #require(loadedMovies(vm).last)
        await vm.loadNextPageIfNeeded(currentItem: newLast)
        #expect(loadedMovies(vm).count == 7)
        #expect(await service.calls == [.popular(page: 1), .popular(page: 2)])
    }

    @Test func nonTrailingItemDoesNotTriggerPagination() async throws {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        await vm.load()
        await vm.loadNextPageIfNeeded(currentItem: try #require(loadedMovies(vm).first))
        #expect(await service.calls == [.popular(page: 1)])
    }

    @Test func duplicateCallsWhileLoadingAreIgnored() async throws {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        async let a: Void = vm.load()
        async let b: Void = vm.load()
        _ = await (a, b)
        #expect(await service.calls == [.popular(page: 1)])
        #expect(loadedMovies(vm).count == 5)
    }

    @Test func errorState() async {
        let service = MockMovieService(error: APIError.httpStatus(code: 401, message: "bad key"))
        let vm = MovieListViewModel(service: service)
        await vm.load()
        #expect(vm.state == .failed("Invalid API key."))
    }

    @Test func retryAfterErrorSucceeds() async {
        let service = MockMovieService(error: APIError.transport(URLError(.notConnectedToInternet)))
        let vm = MovieListViewModel(service: service)
        await vm.load()
        guard case .failed = vm.state else { Issue.record("expected failed"); return }
        await service.setError(nil)
        await vm.refresh()
        #expect(loadedMovies(vm).count == 5)
    }

    @Test func paginationErrorKeepsLoadedMovies() async throws {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        await vm.load()
        await service.setError(APIError.transport(URLError(.timedOut)))
        await vm.loadNextPageIfNeeded(currentItem: try #require(loadedMovies(vm).last))
        #expect(loadedMovies(vm).count == 5)
        #expect(vm.paginationError != nil)
    }

    @Test func refreshResetsPages() async throws {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        await vm.load()
        await vm.loadNextPageIfNeeded(currentItem: try #require(loadedMovies(vm).last))
        #expect(loadedMovies(vm).count == 7)

        await vm.refresh()
        #expect(loadedMovies(vm).count == 5)
        #expect(vm.canLoadMore)
        #expect(await service.calls == [.popular(page: 1), .popular(page: 2), .popular(page: 1)])
    }
}
