import Foundation
import Observation

@Observable
@MainActor
final class SearchViewModel {
    typealias Sleeper = @Sendable (Duration) async throws -> Void

    static let minimumQueryLength = 2

    var query: String = "" {
        didSet { queryDidChange() }
    }

    private(set) var state: ViewState<[Movie]> = .idle

    /// In-flight debounced search. Tests await it to know when work is done.
    private(set) var searchTask: Task<Void, Never>?

    private let service: MovieService
    private let debounce: Duration
    private let sleeper: Sleeper

    /// `sleeper` is injectable so tests skip real waiting.
    init(
        service: MovieService,
        debounce: Duration = .milliseconds(300),
        sleeper: @escaping Sleeper = { try await Task.sleep(for: $0) }
    ) {
        self.service = service
        self.debounce = debounce
        self.sleeper = sleeper
    }

    var movies: [Movie] {
        if case .loaded(let movies) = state { return movies }
        return []
    }

    /// Runs the current query again, e.g. after a failure.
    func retry() {
        queryDidChange()
    }

    private func queryDidChange() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumQueryLength else {
            searchTask = nil
            state = .idle
            return
        }
        searchTask = Task { [debounce, sleeper] in
            do {
                try await sleeper(debounce)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self.performSearch(trimmed)
        }
    }

    private func performSearch(_ text: String) async {
        state = .loading
        do {
            let response = try await service.search(query: text, page: 1)
            guard !Task.isCancelled else { return }
            state = response.results.isEmpty ? .empty : .loaded(response.results)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(MovieListViewModel.message(for: error))
        }
    }
}
