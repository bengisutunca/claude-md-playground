import SwiftUI

/// Popular movies. Embed in a `NavigationStack`.
struct MovieListView: View {
    @State private var viewModel: MovieListViewModel

    private let service: MovieService

    init(viewModel: MovieListViewModel, service: MovieService) {
        _viewModel = State(initialValue: viewModel)
        self.service = service
    }

    var body: some View {
        content
            .navigationTitle("Popular")
            .movieDetailDestination(service: service)
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No Movies", systemImage: "film", message: "No popular movies found.")
        case .failed(let message):
            ErrorView(message: message) { Task { await viewModel.load() } }
        case .loaded(let movies):
            List {
                ForEach(movies) { movie in
                    NavigationLink(value: movie) {
                        MovieRowView(movie: movie)
                    }
                    .task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }
                }
                if let message = viewModel.inlineErrorMessage {
                    Text(message).font(.footnote).foregroundStyle(.red)
                } else if viewModel.hasMorePages {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
            .plainListStyle()
            .refreshable { await viewModel.refresh() }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview
    NavigationStack {
        MovieListView(viewModel: dependencies.makeMovieListViewModel(), service: dependencies.service)
    }
    .environment(dependencies.favorites)
}
