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
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            message("No movies found.", retry: false)
        case .failed(let text):
            message(text, retry: true)
        case .loaded(let movies):
            List {
                ForEach(movies) { movie in
                    MovieRowView(movie: movie)
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

    private func message(_ text: String, retry: Bool) -> some View {
        VStack(spacing: 12) {
            Text(text).multilineTextAlignment(.center).foregroundStyle(.secondary)
            if retry {
                Button("Try Again") { Task { await viewModel.refresh() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
