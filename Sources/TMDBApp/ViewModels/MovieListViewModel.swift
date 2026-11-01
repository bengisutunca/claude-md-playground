import Foundation
import Observation

@MainActor
@Observable
final class MovieListViewModel {
    private(set) var state: ViewState<[Movie]> = .idle
    /// Set when loading a page after the first fails; the already loaded movies stay visible.
    private(set) var paginationError: String?
    private(set) var isLoadingNextPage = false

    private var movies: [Movie] = []
    private var currentPage = 0
    private var totalPages = 1
    private var isFetching = false
    /// Incremented on refresh so results of superseded requests are dropped.
    private var generation = 0

    @ObservationIgnored private let service: any MovieService

    init(service: any MovieService) {
        self.service = service
    }

    var canLoadMore: Bool { currentPage < totalPages }

    /// Initial load. No-op if already loaded or a request is in flight.
    func load() async {
        guard !isFetching, currentPage == 0 else { return }
        state = .loading
        await fetch(page: 1)
    }

    /// Discards loaded pages and reloads from page 1.
    func refresh() async {
        generation += 1
        isLoadingNextPage = false
        paginationError = nil
        if movies.isEmpty { state = .loading }
        await fetch(page: 1, replacing: true)
    }

    /// Loads the next page when `currentItem` is at (or near) the end of the list.
    func loadNextPageIfNeeded(currentItem: Movie) async {
        guard !isFetching, canLoadMore, currentPage > 0,
              let index = movies.firstIndex(where: { $0.id == currentItem.id }),
              index >= movies.count - 3 else { return }
        isLoadingNextPage = true
        paginationError = nil
        await fetch(page: currentPage + 1)
    }

    private func fetch(page: Int, replacing: Bool = false) async {
        isFetching = true
        let token = generation
        defer {
            if token == generation {
                isFetching = false
                isLoadingNextPage = false
            }
        }
        do {
            let response = try await service.popular(page: page)
            guard token == generation else { return }
            if replacing { movies = [] }
            let known = Set(movies.map(\.id))
            movies += response.results.filter { !known.contains($0.id) }
            currentPage = response.page
            totalPages = response.totalPages
            state = movies.isEmpty ? .empty : .loaded(movies)
        } catch is CancellationError {
            return
        } catch {
            guard token == generation else { return }
            let message = error.userMessage
            if movies.isEmpty {
                state = .failed(message)
            } else {
                paginationError = message
            }
        }
    }
}
