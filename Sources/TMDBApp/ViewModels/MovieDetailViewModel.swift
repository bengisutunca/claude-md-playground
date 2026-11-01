import Foundation
import Observation

struct MovieDetailContent: Equatable, Sendable {
    let detail: MovieDetail
    /// Top 10 cast members ordered by `order`.
    let cast: [CastMember]
    let directors: [CrewMember]

    var runtimeText: String? {
        guard let runtime = detail.runtime, runtime > 0 else { return nil }
        return Self.formatRuntime(minutes: runtime)
    }

    var genresText: String { detail.genres.map(\.name).joined(separator: ", ") }

    var releaseYear: String? { detail.year }

    var directorsText: String { directors.map(\.name).joined(separator: ", ") }

    /// "2h 28m", "2h" for exact hours, "45m" under an hour, "0m" for zero.
    static func formatRuntime(minutes: Int) -> String {
        let minutes = max(0, minutes)
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}

@MainActor
@Observable
final class MovieDetailViewModel {
    private(set) var state: ViewState<MovieDetailContent> = .idle

    let movieID: Int
    @ObservationIgnored private let service: any MovieService

    init(movieID: Int, service: any MovieService) {
        self.movieID = movieID
        self.service = service
    }

    /// Loads detail and credits concurrently. No-op while loading or once loaded.
    func load() async {
        switch state {
        case .loading, .loaded: return
        default: break
        }
        state = .loading
        do {
            async let detail = service.detail(id: movieID)
            async let credits = service.credits(id: movieID)
            let (d, c) = try await (detail, credits)
            let cast = c.cast
                .sorted { ($0.order ?? .max) < ($1.order ?? .max) }
                .prefix(10)
            let directors = c.crew.filter { $0.job == "Director" }
            state = .loaded(MovieDetailContent(detail: d, cast: Array(cast), directors: directors))
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(MovieListViewModel.message(for: error))
        }
    }

    func retry() async {
        state = .idle
        await load()
    }
}
