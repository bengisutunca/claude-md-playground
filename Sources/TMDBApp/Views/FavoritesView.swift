import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesViewModel.self) private var viewModel

    var body: some View {
        Group {
            if viewModel.favorites.isEmpty {
                Text("No favorites yet.").foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(viewModel.favorites) { movie in
                        MovieRowView(movie: movie)
                    }
                    .onDelete { viewModel.remove(at: $0) }
                }
                #if os(iOS)
                .listStyle(.plain)
                #endif
            }
        }
        .navigationTitle("Favorites")
    }
}
