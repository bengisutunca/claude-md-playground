import Foundation
import Observation

struct MovieDetailContent: Hashable, Sendable {
    static let maxCastCount = 10

    let detail: MovieDetail
    /// Top billed cast, ordered by `order`.
    let cast: [CastMember]
    let directors: [CrewMember]

    /// Runtime as "2h 28m", "45m" or "2h". `nil` when runtime is unknown.
    var runtimeText: String? { Self.formatRuntime(minutes: detail.runtime) }

    /// Genre names joined with ", ".
    var genresText: String { detail.genres.map(\.name).joined(separator: ", ") }

    var releaseYear: String? { detail.year }

    static func formatRuntime(minutes: Int?) -> String? {
        guard let minutes, minutes >= 0 else { return nil }
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest)m" }
        if rest == 0 { return "\(hours)h" }
        return "\(hours)h \(rest)m"
    }
}

@Observable
@MainActor
final class MovieDetailViewModel {
    private(set) var state: ViewState<MovieDetailContent> = .idle

    let movieID: Int
    private let service: MovieService

    init(movieID: Int, service: MovieService) {
        self.movieID = movieID
        self.service = service
    }

    /// Loads detail and credits concurrently. Does nothing unless state is `idle` or `failed`.
    func load() async {
        switch state {
        case .idle, .failed: break
        default: return
        }
        state = .loading
        do {
            async let detail = service.detail(id: movieID)
            async let credits = service.credits(id: movieID)
            let (movieDetail, movieCredits) = try await (detail, credits)
            state = .loaded(Self.content(detail: movieDetail, credits: movieCredits))
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(MovieListViewModel.message(for: error))
        }
    }

    static func content(detail: MovieDetail, credits: Credits) -> MovieDetailContent {
        let cast = credits.cast
            .sorted { ($0.order ?? .max) < ($1.order ?? .max) }
            .prefix(MovieDetailContent.maxCastCount)
        let directors = credits.crew.filter { $0.job == "Director" }
        return MovieDetailContent(detail: detail, cast: Array(cast), directors: directors)
    }
}
