import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesViewModel.self) private var favorites
    private let service: any MovieService

    init(service: any MovieService) {
        self.service = service
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.favorites.isEmpty {
                    Text("No favorites yet.\nTap the heart on a movie to add it.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
}
