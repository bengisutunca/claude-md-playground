import Foundation
import Observation

@Observable
@MainActor
final class MovieListViewModel {
    private(set) var state: ViewState<[Movie]> = .idle
    /// Set when a refresh or next-page request fails while movies are already shown.
    private(set) var inlineErrorMessage: String?

    private let service: MovieService
    private let prefetchDistance: Int
    private var currentPage = 0
    private var totalPages = 1
    private var isFetching = false

    init(service: MovieService, prefetchDistance: Int = 3) {
        self.service = service
        self.prefetchDistance = prefetchDistance
    }

    var movies: [Movie] {
        if case .loaded(let movies) = state { return movies }
        return []
    }

    var hasMorePages: Bool { currentPage < totalPages }

    /// User-facing error text, from a full-screen failure or an inline one.
    var errorMessage: String? {
        if case .failed(let message) = state { return message }
        return inlineErrorMessage
    }

    /// First load. Does nothing unless state is `idle` or `failed`.
    func load() async {
        switch state {
        case .idle, .failed: break
        default: return
        }
        guard !isFetching else { return }
        state = .loading
        await fetch(page: 1, replacing: true)
    }

    /// Reloads page 1 and drops later pages. Keeps current movies if the request fails.
    func refresh() async {
        guard !isFetching else { return }
        await fetch(page: 1, replacing: true)
    }

    func loadNextPageIfNeeded(currentItem: Movie) async {
        guard hasMorePages, !isFetching,
            let index = movies.firstIndex(where: { $0.id == currentItem.id }),
            index >= movies.count - prefetchDistance
        else { return }
        await fetch(page: currentPage + 1, replacing: false)
    }

    private func fetch(page: Int, replacing: Bool) async {
        isFetching = true
        defer { isFetching = false }
        inlineErrorMessage = nil
        do {
            let response = try await service.popular(page: page)
            var all = replacing ? [] : movies
            let known = Set(all.map(\.id))
            all += response.results.filter { !known.contains($0.id) }
            currentPage = response.page
            totalPages = response.totalPages
            state = all.isEmpty ? .empty : .loaded(all)
        } catch is CancellationError {
            if case .loading = state { state = .idle }
        } catch {
            let message = Self.message(for: error)
            if movies.isEmpty {
                state = .failed(message)
            } else {
                inlineErrorMessage = message
            }
        }
    }

    static func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "Something went wrong. Please try again."
        }
        switch apiError {
        case .transport:
            return "Can't reach the server. Check your connection and try again."
        case .httpStatus(let code, let message):
            if code == 401 { return "Invalid API key." }
            return message ?? "Server error (\(code)). Please try again."
        case .decoding, .invalidResponse:
            return "Received an unexpected response from the server."
        case .missingAPIKey:
            return "API key is missing."
        }
    }
}
