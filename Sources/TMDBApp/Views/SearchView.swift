import SwiftUI

/// Movie search. Embed in a `NavigationStack`.
struct SearchView: View {
    @State private var viewModel: SearchViewModel

    private let service: MovieService

    init(viewModel: SearchViewModel, service: MovieService) {
        _viewModel = State(initialValue: viewModel)
        self.service = service
    }

    var body: some View {
        content
            .navigationTitle("Search")
            .movieDetailDestination(service: service)
            .searchable(text: $viewModel.query, prompt: "Search movies")
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyStateView(
                title: "Search Movies", systemImage: "magnifyingglass",
                message: "Type at least \(SearchViewModel.minimumQueryLength) characters to search.")
        case .loading:
            LoadingView()
        case .empty:
            EmptyStateView(
                title: "No Results", systemImage: "film",
                message: "No movies found for \"\(viewModel.query)\".")
        case .failed(let message):
            ErrorView(message: message) { viewModel.retry() }
        case .loaded(let movies):
            List(movies) { movie in
                NavigationLink(value: movie) {
                    MovieRowView(movie: movie)
                }
            }
            .plainListStyle()
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview
    NavigationStack {
        SearchView(viewModel: dependencies.makeSearchViewModel(), service: dependencies.service)
    }
    .environment(dependencies.favorites)
}
