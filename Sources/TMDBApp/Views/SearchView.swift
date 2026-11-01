import SwiftUI

/// Movie search. Expects to be hosted in a `NavigationStack` (see `RootView`).
struct SearchView: View {
    @State private var viewModel: SearchViewModel
    private let service: any MovieService

    init(viewModel: SearchViewModel, service: any MovieService) {
        _viewModel = State(initialValue: viewModel)
        self.service = service
    }

    var body: some View {
        content
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: "Search movies")
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            #endif
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(viewModel: MovieDetailViewModel(movieID: movie.id, service: service))
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateView(title: "Search Movies", systemImage: "magnifyingglass",
                           message: "Type at least \(SearchViewModel.minimumQueryLength) characters to search.")
        case .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No Results", systemImage: "magnifyingglass",
                           message: "Nothing found for \"\(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines))\".")
        case .failed(let text):
            ErrorView(message: text) { viewModel.retry() }
        case .loaded(let movies):
            List(movies) { movie in
                NavigationLink(value: movie) { MovieRowView(movie: movie) }
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview
    return NavigationStack {
        SearchView(viewModel: dependencies.makeSearchViewModel(), service: dependencies.movieService)
    }
    .environment(dependencies.favorites)
}
