import Testing
@testable import TMDBApp

@MainActor
struct MovieListViewModelTests {
    @Test func firstLoad() async {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        #expect(vm.state == .idle)
        await vm.load()
        #expect(vm.movies.map(\.id) == [27205, 157336, 155, 278, 550])
        #expect(vm.hasMorePages)
        #expect(service.calls == [.popular(page: 1)])
    }

    @Test func paginatesAcrossPages() async {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        await vm.load()
        await vm.loadNextPageIfNeeded(currentItem: vm.movies.last!)
        #expect(vm.movies.map(\.id) == [27205, 157336, 155, 278, 550, 129, 496243])
        #expect(service.calls == [.popular(page: 1), .popular(page: 2)])
    }

    @Test func nonTailItemDoesNotLoadMore() async {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        await vm.load()
        await vm.loadNextPageIfNeeded(currentItem: vm.movies.first!)
        #expect(service.calls == [.popular(page: 1)])
    }

    @Test func stopsAtTotalPages() async {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        await vm.load()
        await vm.loadNextPageIfNeeded(currentItem: vm.movies.last!)
        #expect(!vm.hasMorePages)
        await vm.loadNextPageIfNeeded(currentItem: vm.movies.last!)
        #expect(service.calls.count == 2)
        #expect(vm.movies.count == 7)
    }

    @Test func ignoresDuplicateCallsWhileLoading() async {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        async let a: Void = vm.load()
        async let b: Void = vm.load()
        _ = await (a, b)
        #expect(service.calls == [.popular(page: 1)])
        #expect(vm.movies.count == 5)
    }

    @Test func failureShowsMessage() async {
        let service = MockMovieService(error: APIError.httpStatus(code: 401, message: "bad key"))
        let vm = MovieListViewModel(service: service)
        await vm.load()
        #expect(vm.state == .failed("Invalid API key."))
        #expect(vm.errorMessage == "Invalid API key.")
    }

    @Test func retryAfterFailureSucceeds() async {
        let service = MockMovieService(error: APIError.invalidResponse)
        let vm = MovieListViewModel(service: service)
        await vm.load()
        service.error = nil
        await vm.load()
        #expect(vm.movies.count == 5)
        #expect(vm.errorMessage == nil)
    }

    @Test func nextPageFailureKeepsMovies() async {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        await vm.load()
        service.error = APIError.invalidResponse
        await vm.loadNextPageIfNeeded(currentItem: vm.movies.last!)
        #expect(vm.movies.count == 5)
        #expect(vm.errorMessage != nil)
    }

    @Test func refreshResetsPages() async {
        let service = MockMovieService()
        let vm = MovieListViewModel(service: service)
        await vm.load()
        await vm.loadNextPageIfNeeded(currentItem: vm.movies.last!)
        #expect(vm.movies.count == 7)
        await vm.refresh()
        #expect(vm.movies.count == 5)
        #expect(vm.hasMorePages)
        #expect(service.calls.last == .popular(page: 1))
    }
}
