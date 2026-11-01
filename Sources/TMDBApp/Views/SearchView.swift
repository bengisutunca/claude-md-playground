import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel

    private let service: MovieService

    init(viewModel: SearchViewModel, service: MovieService) {
        _viewModel = State(initialValue: viewModel)
        self.service = service
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search")
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(viewModel: MovieDetailViewModel(movieID: movie.id, service: service))
                }
                .searchable(text: $viewModel.query, prompt: "Search movies")
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Text("Type at least 2 characters to search.").foregroundStyle(.secondary)
        case .loading:
            ProgressView()
        case .empty:
            Text("No movies found for \"\(viewModel.query)\".").foregroundStyle(.secondary)
        case .failed(let message):
            Text(message).multilineTextAlignment(.center).padding()
        case .loaded(let movies):
            List(movies) { movie in
                NavigationLink(value: movie) {
                    MovieRowView(movie: movie)
                }
            }
            #if os(iOS)
            .listStyle(.plain)
            #endif
        }
    }
}
