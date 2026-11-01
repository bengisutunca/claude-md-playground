import Testing
@testable import TMDBApp

@MainActor
struct SearchViewModelTests {
    /// Returns at once, but throws if the task was cancelled. No real waiting.
    private static let instant: SearchViewModel.Sleeper = { _ in try Task.checkCancellation() }

    private func makeViewModel(_ service: MockMovieService) -> SearchViewModel {
        SearchViewModel(service: service, sleeper: Self.instant)
    }

    @Test func shortQueryDoesNotCallService() async {
        let service = MockMovieService()
        let vm = makeViewModel(service)
        vm.query = "i"
        await vm.searchTask?.value
        vm.query = "  a  "
        await vm.searchTask?.value
        #expect(vm.state == .idle)
        #expect(service.calls.isEmpty)
    }

    @Test func shortQueryClearsResults() async {
        let service = MockMovieService()
        let vm = makeViewModel(service)
        vm.query = "inception"
        await vm.searchTask?.value
        #expect(!vm.movies.isEmpty)
        vm.query = "i"
        #expect(vm.state == .idle)
    }

    @Test func rapidTypingTriggersOneSearch() async {
        let service = MockMovieService()
        let vm = makeViewModel(service)
        for text in ["in", "inc", "ince", "incep", "inception"] {
            vm.query = text
        }
        await vm.searchTask?.value
        #expect(service.calls == [.search(query: "inception", page: 1)])
    }

    @Test func searchInceptionLoadsResults() async {
        let service = MockMovieService()
        let vm = makeViewModel(service)
        vm.query = "  Inception "
        await vm.searchTask?.value
        #expect(vm.movies.first?.id == 27205)
        #expect(service.calls == [.search(query: "Inception", page: 1)])
    }

    @Test func emptyResultGivesEmptyState() async {
        let service = MockMovieService()
        let vm = makeViewModel(service)
        vm.query = "zzzzzz"
        await vm.searchTask?.value
        #expect(vm.state == .empty)
    }

    @Test func errorGivesFailedState() async {
        let service = MockMovieService(error: APIError.httpStatus(code: 401, message: "bad key"))
        let vm = makeViewModel(service)
        vm.query = "inception"
        await vm.searchTask?.value
        #expect(vm.state == .failed("Invalid API key."))
    }
}
