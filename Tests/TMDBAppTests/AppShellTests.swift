import Foundation
import Testing
@testable import TMDBApp

@MainActor
@Suite("App shell")
struct AppShellTests {
    @Test func missingAPIKeyYieldsClearMessage() async {
        let vm = MovieListViewModel(service: MockMovieService(error: APIError.missingAPIKey))
        await vm.load()
        guard case .failed(let message) = vm.state else {
            Issue.record("expected failed state")
            return
        }
        #expect(message.contains("API key is missing"))
        #expect(message.contains("TMDB_API_KEY"))
    }

    @Test func clientWithoutKeyThrowsInsteadOfCrashing() async {
        let config = try? APIConfiguration.load(environment: [:], bundle: Bundle(for: Probe.self))
        #expect(config == nil)
    }

    @Test func previewDependenciesServeMockData() async throws {
        let deps = AppDependencies.preview
        let page = try await deps.movieService.popular(page: 1)
        #expect(!page.results.isEmpty)
        #expect(!deps.favorites.favorites.isEmpty)
        let detail = try await deps.movieService.detail(id: 1)
        #expect(detail.title == "Inception")
        #expect(try await deps.movieService.credits(id: 1).cast.count == 1)
    }

    @Test func searchRetryReRunsQuery() async {
        let service = MockMovieService()
        let vm = SearchViewModel(service: service, sleep: { _ in })
        vm.query = "inception"
        await vm.waitForSearch()
        vm.retry()
        await vm.waitForSearch()
        let calls = await service.calls
        #expect(calls.count == 2)
    }

    private final class Probe {}
}
