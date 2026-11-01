import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    static let minimumQueryLength = 2

    var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            queryDidChange()
        }
    }
    private(set) var state: ViewState<[Movie]> = .idle

    @ObservationIgnored private let service: any MovieService
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private let sleep: @Sendable (Duration) async throws -> Void
    @ObservationIgnored private var searchTask: Task<Void, Never>?

    /// - Parameters:
    ///   - debounce: Delay before a search starts after the last keystroke.
    ///   - sleep: Injectable sleeper; tests pass a no-op to avoid real waiting.
    init(service: any MovieService,
         debounce: Duration = .milliseconds(300),
         sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.service = service
        self.debounce = debounce
        self.sleep = sleep
    }

    /// Waits for the currently scheduled search (if any) to finish.
    func waitForSearch() async {
        await searchTask?.value
    }

    /// Re-runs the search for the current query (e.g. after a failure).
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
        searchTask = Task { [debounce, sleep] in
            do { try await sleep(debounce) } catch { return }
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
            state = .failed(error.userMessage)
        }
    }
}
