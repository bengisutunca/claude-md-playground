import Foundation
import Testing
@testable import TMDBApp

@MainActor
@Suite("MovieDetailViewModel")
struct MovieDetailViewModelTests {
    @Test func successfulLoad() async throws {
        let service = MockMovieService()
        let vm = MovieDetailViewModel(movieID: 27205, service: service)
        #expect(vm.state == .idle)
        await vm.load()
        guard case .loaded(let content) = vm.state else {
            Issue.record("expected loaded, got \(vm.state)"); return
        }
        #expect(content.detail.id == 27205)
        #expect(content.cast.count <= 10)
        #expect(!content.cast.isEmpty)
        let orders = content.cast.compactMap(\.order)
        #expect(orders == orders.sorted())
        #expect(content.directors.allSatisfy { $0.job == "Director" })
        #expect(!content.directors.isEmpty)
        let calls = await service.calls
        #expect(calls.count == 2)
        #expect(calls.contains(.detail(id: 27205)))
        #expect(calls.contains(.credits(id: 27205)))
    }

    @Test func failureGivesFailedState() async {
        let service = MockMovieService(error: APIError.transport(URLError(.notConnectedToInternet)))
        let vm = MovieDetailViewModel(movieID: 27205, service: service)
        await vm.load()
        guard case .failed = vm.state else { Issue.record("expected failed"); return }
    }

    /// Service where only one of the two requests fails.
    private struct PartialService: MovieService {
        let failDetail: Bool
        let base = MockMovieService()
        func popular(page: Int) async throws -> PagedResponse<Movie> { try await base.popular(page: page) }
        func search(query: String, page: Int) async throws -> PagedResponse<Movie> {
            try await base.search(query: query, page: page)
        }
        func detail(id: Int) async throws -> MovieDetail {
            if failDetail { throw APIError.httpStatus(code: 404, message: nil) }
            return try await base.detail(id: id)
        }
        func credits(id: Int) async throws -> Credits {
            if !failDetail { throw APIError.httpStatus(code: 500, message: nil) }
            return try await base.credits(id: id)
        }
    }

    @Test(arguments: [true, false])
    func eitherRequestFailingGivesFailed(failDetail: Bool) async {
        let vm = MovieDetailViewModel(movieID: 27205, service: PartialService(failDetail: failDetail))
        await vm.load()
        guard case .failed = vm.state else { Issue.record("expected failed"); return }
    }

    @Test(arguments: [(0, "0m"), (5, "5m"), (59, "59m"), (60, "1h"), (120, "2h"),
                      (148, "2h 28m"), (61, "1h 1m")])
    func runtimeFormatting(minutes: Int, expected: String) {
        #expect(MovieDetailContent.formatRuntime(minutes: minutes) == expected)
    }

    @Test func helpersFromFixture() async throws {
        let vm = MovieDetailViewModel(movieID: 27205, service: MockMovieService())
        await vm.load()
        guard case .loaded(let content) = vm.state else { Issue.record("expected loaded"); return }
        #expect(content.runtimeText == "2h 28m")
        #expect(content.genresText.contains(", "))
        #expect(content.releaseYear == "2010")
    }
}
