import SwiftUI

/// Saved favorites. Embed in a `NavigationStack`. Needs `FavoritesViewModel` in the environment.
struct FavoritesView: View {
    @Environment(FavoritesViewModel.self) private var viewModel

    var body: some View {
        Group {
            if viewModel.favorites.isEmpty {
                EmptyStateView(
                    title: "No Favorites", systemImage: "heart",
                    message: "Tap the heart on a movie to save it here.")
            } else {
                List {
                    ForEach(viewModel.favorites) { movie in
                        MovieRowView(movie: movie)
                    }
                    .onDelete { viewModel.remove(at: $0) }
                }
                .plainListStyle()
            }
        }
        .navigationTitle("Favorites")
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environment(AppDependencies.preview.favorites)
}

#Preview("Empty") {
    NavigationStack {
        FavoritesView()
    }
    .environment(FavoritesViewModel(store: InMemoryFavoritesStore()))
}
