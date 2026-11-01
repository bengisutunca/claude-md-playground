import Foundation
import Testing
@testable import TMDBApp

@Suite("AppDependencies")
@MainActor
struct AppDependenciesTests {
    @Test func missingKeyMakesScreensFailWithMessage() async {
        let deps = AppDependencies.make(
            loadConfiguration: { throw APIError.missingAPIKey },
            favoritesStore: InMemoryFavoritesStore())
        let vm = deps.makeMovieListViewModel()
        await vm.load()
        #expect(vm.state == .failed(MovieListViewModel.message(for: APIError.missingAPIKey)))
    }

    @Test func previewServesOfflineData() async throws {
        let deps = AppDependencies.preview
        let page = try await deps.service.popular(page: 1)
        #expect(!page.results.isEmpty)
        #expect(!deps.favorites.favorites.isEmpty)
        let detail = try await deps.service.detail(id: 27205)
        #expect(detail.title == "Inception")
        let credits = try await deps.service.credits(id: 27205)
        #expect(!credits.cast.isEmpty)
    }

    @Test func configuredKeyBuildsRealService() {
        let deps = AppDependencies.make(
            loadConfiguration: { APIConfiguration(apiKey: "k") },
            favoritesStore: InMemoryFavoritesStore())
        #expect(deps.service is TMDBMovieService)
    }
}
