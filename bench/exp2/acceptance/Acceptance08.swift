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

@MainActor
@Suite("Acceptance 08: app shell", .serialized)
struct Acceptance08Tests {
    @Test func previewServesMockData() async throws {
        let deps = AppDependencies.preview
        let page = try await deps.movieService.popular(page: 1)
        #expect(page.results.isEmpty == false)
    }

    @Test func previewListViewModelLoads() async throws {
        let deps = AppDependencies.preview
        let vm = deps.makeMovieListViewModel()
        await vm.load()
        guard case .loaded(let movies) = vm.state else {
            Issue.record("expected .loaded, got \(vm.state)")
            return
        }
        #expect(movies.isEmpty == false)
    }

    @Test func liveWithoutKeyFailsCleanly() async throws {
        unsetenv("TMDB_API_KEY")
        let deps = AppDependencies.live()
        do {
            _ = try await deps.movieService.popular(page: 1)
            Issue.record("expected APIError.missingAPIKey")
        } catch let error as APIError {
            guard case .missingAPIKey = error else { Issue.record("got \(error)"); return }
        } catch {
            Issue.record("unexpected error \(error)")
        }
        let vm = deps.makeMovieListViewModel()
        await vm.load()
        guard case .failed(let message) = vm.state else {
            Issue.record("expected .failed, got \(vm.state)")
            return
        }
        #expect(message.isEmpty == false)
    }

    @Test func searchViewModelComesFromDependencies() async throws {
        let deps = AppDependencies.preview
        let vm = deps.makeSearchViewModel()
        vm.query = "a"
        await vm.waitForSearch()
        guard case .idle = vm.state else {
            Issue.record("expected .idle, got \(vm.state)")
            return
        }
    }

    @Test func viewsCanBeBuilt() {
        _ = LoadingView()
        _ = EmptyStateView(title: "No results", systemImage: "film", message: "Try another title.")
        _ = ErrorView(message: "Something failed", retry: {})
        _ = RootView(dependencies: .preview)
    }
}
