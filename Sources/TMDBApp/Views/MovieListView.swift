import SwiftUI

/// Popular movies. Expects to be hosted in a `NavigationStack` (see `RootView`).
struct MovieListView: View {
    @State private var viewModel: MovieListViewModel
    private let service: any MovieService

    init(viewModel: MovieListViewModel, service: any MovieService) {
        _viewModel = State(initialValue: viewModel)
        self.service = service
    }

    var body: some View {
        content
            .navigationTitle("Popular")
            .task { await viewModel.load() }
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(viewModel: MovieDetailViewModel(movieID: movie.id, service: service))
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView()
        case .empty:
            EmptyStateView(title: "No Movies", systemImage: "film")
        case .failed(let text):
            ErrorView(message: text) { Task { await viewModel.refresh() } }
        case .loaded(let movies):
            List {
                ForEach(movies) { movie in
                    NavigationLink(value: movie) { MovieRowView(movie: movie) }
                        .task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }
                }
                footer
            }
            .refreshable { await viewModel.refresh() }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if viewModel.isLoadingNextPage {
            ProgressView().frame(maxWidth: .infinity)
        } else if let error = viewModel.paginationError {
            VStack(spacing: 8) {
                Text(error).font(.footnote).foregroundStyle(.secondary)
                Button("Retry") {
                    Task { await viewModel.refresh() }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview
    return NavigationStack {
        MovieListView(viewModel: dependencies.makeMovieListViewModel(), service: dependencies.movieService)
    }
    .environment(dependencies.favorites)
}
