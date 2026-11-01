import SwiftUI

struct MovieListView: View {
    @State private var viewModel: MovieListViewModel

    init(viewModel: MovieListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Popular")
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .empty:
            Text("No movies found.").foregroundStyle(.secondary)
        case .failed(let message):
            VStack(spacing: 12) {
                Text(message).multilineTextAlignment(.center)
                Button("Retry") { Task { await viewModel.load() } }
            }
            .padding()
        case .loaded(let movies):
            List {
                ForEach(movies) { movie in
                    MovieRowView(movie: movie)
                        .task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }
                }
                if let message = viewModel.inlineErrorMessage {
                    Text(message).font(.footnote).foregroundStyle(.red)
                } else if viewModel.hasMorePages {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
            #if os(iOS)
            .listStyle(.plain)
            #endif
            .refreshable { await viewModel.refresh() }
        }
    }
}
