import SwiftUI

/// Saved movies. Expects to be hosted in a `NavigationStack` (see `RootView`).
struct FavoritesView: View {
    @Environment(FavoritesViewModel.self) private var favorites
    private let service: any MovieService

    init(service: any MovieService) {
        self.service = service
    }

    var body: some View {
        Group {
            if favorites.favorites.isEmpty {
                EmptyStateView(title: "No Favorites", systemImage: "heart",
                               message: "Tap the heart on a movie to add it.")
            } else {
                List {
                    ForEach(favorites.favorites) { movie in
                        NavigationLink(value: movie) { MovieRowView(movie: movie) }
                    }
                    .onDelete { favorites.remove(at: $0) }
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationDestination(for: Movie.self) { movie in
            MovieDetailView(viewModel: MovieDetailViewModel(movieID: movie.id, service: service))
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview
    return NavigationStack {
        FavoritesView(service: dependencies.movieService)
    }
    .environment(dependencies.favorites)
}
