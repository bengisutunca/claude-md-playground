import Foundation
import Testing
@testable import TMDBApp

/// Fails only the chosen request; the other returns fixture data.
private struct SelectiveFailureService: MovieService {
    let failDetail: Bool
    let failCredits: Bool
    let base = MockMovieService()

    func popular(page: Int) async throws -> PagedResponse<Movie> { try await base.popular(page: page) }
    func search(query: String, page: Int) async throws -> PagedResponse<Movie> {
        try await base.search(query: query, page: page)
    }
    func detail(id: Int) async throws -> MovieDetail {
        if failDetail { throw APIError.invalidResponse }
        return try await base.detail(id: id)
    }
    func credits(id: Int) async throws -> Credits {
        if failCredits { throw APIError.invalidResponse }
        return try await base.credits(id: id)
    }
}

@MainActor
struct MovieDetailViewModelTests {
    @Test func successfulLoad() async throws {
        let service = MockMovieService()
        let vm = MovieDetailViewModel(movieID: 27205, service: service)
        #expect(vm.state == .idle)
        await vm.load()
        guard case .loaded(let content) = vm.state else {
            Issue.record("expected loaded, got \(vm.state)")
            return
        }
        #expect(content.detail.id == 27205)
        #expect(!content.cast.isEmpty)
        #expect(content.cast.count <= 10)
        let orders = content.cast.compactMap(\.order)
        #expect(orders == orders.sorted())
        #expect(!content.directors.isEmpty)
        #expect(content.directors.allSatisfy { $0.job == "Director" })
        #expect(service.calls.count == 2)
        #expect(service.calls.contains(.detail(id: 27205)))
        #expect(service.calls.contains(.credits(id: 27205)))
    }

    @Test func castLimitedToTenByOrder() throws {
        let detail = try JSONDecoder.tmdb.decode(MovieDetail.self, from: Fixture.data("movie_detail_27205"))
        let cast = (0..<15).reversed().map {
            CastMember(id: $0, name: "A\($0)", character: nil, order: $0, profilePath: nil)
        }
        let content = MovieDetailViewModel.content(
            detail: detail, credits: Credits(id: 1, cast: cast, crew: []))
        #expect(content.cast.map(\.order) == Array(0..<10))
    }

    @Test func detailFailureGivesFailed() async {
        let vm = MovieDetailViewModel(
            movieID: 27205, service: SelectiveFailureService(failDetail: true, failCredits: false))
        await vm.load()
        #expect(vm.state == .failed(MovieListViewModel.message(for: APIError.invalidResponse)))
    }

    @Test func creditsFailureGivesFailed() async {
        let vm = MovieDetailViewModel(
            movieID: 27205, service: SelectiveFailureService(failDetail: false, failCredits: true))
        await vm.load()
        #expect(vm.state == .failed(MovieListViewModel.message(for: APIError.invalidResponse)))
    }

    @Test func retryAfterFailureSucceeds() async {
        let service = MockMovieService(error: APIError.invalidResponse)
        let vm = MovieDetailViewModel(movieID: 27205, service: service)
        await vm.load()
        service.error = nil
        await vm.load()
        if case .loaded = vm.state {} else { Issue.record("expected loaded, got \(vm.state)") }
    }

    @Test func formattedHelpers() async {
        let vm = MovieDetailViewModel(movieID: 27205, service: MockMovieService())
        await vm.load()
        guard case .loaded(let content) = vm.state else {
            Issue.record("expected loaded")
            return
        }
        #expect(content.runtimeText == "2h 28m")
        #expect(content.genresText == content.detail.genres.map(\.name).joined(separator: ", "))
        #expect(content.releaseYear == "2010")
    }

    @Test(arguments: [
        (0, "0m"), (1, "1m"), (59, "59m"), (60, "1h"), (120, "2h"), (61, "1h 1m"), (148, "2h 28m"),
    ])
    func runtimeFormatting(minutes: Int, expected: String) {
        #expect(MovieDetailContent.formatRuntime(minutes: minutes) == expected)
    }

    @Test func runtimeUnknown() {
        #expect(MovieDetailContent.formatRuntime(minutes: nil) == nil)
        #expect(MovieDetailContent.formatRuntime(minutes: -5) == nil)
    }
}
