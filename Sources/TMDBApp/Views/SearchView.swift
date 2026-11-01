import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    private let service: any MovieService

    init(viewModel: SearchViewModel, service: any MovieService) {
        _viewModel = State(initialValue: viewModel)
        self.service = service
    }

    var body: some View {
        NavigationStack {
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
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            message("Type at least 2 characters to search.")
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            message("No results for \"\(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines))\".")
        case .failed(let text):
            message(text)
        case .loaded(let movies):
            List(movies) { movie in
                NavigationLink(value: movie) { MovieRowView(movie: movie) }
            }
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
