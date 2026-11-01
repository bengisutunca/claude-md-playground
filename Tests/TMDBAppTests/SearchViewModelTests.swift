import Foundation
import Testing
@testable import TMDBApp

@MainActor
@Suite("SearchViewModel")
struct SearchViewModelTests {
    private func makeVM(_ service: MockMovieService) -> SearchViewModel {
        SearchViewModel(service: service, sleep: { _ in })
    }

    @Test func shortQueryDoesNotCallService() async {
        let service = MockMovieService()
        let vm = makeVM(service)
        vm.query = "a"
        await vm.waitForSearch()
        vm.query = "  b "
        await vm.waitForSearch()
        #expect(vm.state == .idle)
        #expect(await service.calls.isEmpty)
    }

    @Test func shortQueryClearsPreviousResults() async {
        let service = MockMovieService()
        let vm = makeVM(service)
        vm.query = "inception"
        await vm.waitForSearch()
        #expect(vm.state != .idle)
        vm.query = "i"
        #expect(vm.state == .idle)
    }

    @Test func rapidTypingTriggersOneSearch() async {
        let service = MockMovieService()
        let vm = makeVM(service)
        for q in ["in", "inc", "ince", "incep", "inception"] { vm.query = q }
        await vm.waitForSearch()
        #expect(await service.calls == [.search(query: "inception", page: 1)])
    }

    @Test func searchInception() async {
        let service = MockMovieService()
        let vm = makeVM(service)
        vm.query = "inception"
        await vm.waitForSearch()
        guard case .loaded(let movies) = vm.state else { Issue.record("expected loaded, got \(vm.state)"); return }
        #expect(movies.contains { $0.id == 27205 })
    }

    @Test func emptyResultIsEmptyState() async {
        let service = MockMovieService()
        let vm = makeVM(service)
        vm.query = "empty"
        await vm.waitForSearch()
        #expect(vm.state == .empty)
    }

    @Test func errorState() async {
        let service = MockMovieService(error: APIError.httpStatus(code: 401, message: "bad key"))
        let vm = makeVM(service)
        vm.query = "inception"
        await vm.waitForSearch()
        #expect(vm.state == .failed("Invalid API key."))
    }
}
