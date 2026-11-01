import SwiftUI

/// App shell: Popular, Search and Favorites tabs, each in its own `NavigationStack`.
@MainActor
struct RootView: View {
    private let dependencies: AppDependencies

    /// Uses `AppDependencies.live` when `dependencies` is `nil`.
    init(dependencies: AppDependencies? = nil) {
        self.dependencies = dependencies ?? .live
    }

    var body: some View {
        TabView {
            NavigationStack {
                MovieListView(viewModel: dependencies.makeMovieListViewModel(), service: dependencies.service)
            }
            .tabItem { Label("Popular", systemImage: "flame") }

            NavigationStack {
                SearchView(viewModel: dependencies.makeSearchViewModel(), service: dependencies.service)
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }

            NavigationStack {
                FavoritesView()
            }
            .tabItem { Label("Favorites", systemImage: "heart") }
        }
        .environment(dependencies.favorites)
    }
}

#Preview {
    RootView(dependencies: .preview)
}

#Preview("Missing API key") {
    RootView(dependencies: .make(loadConfiguration: { throw APIError.missingAPIKey }, favoritesStore: InMemoryFavoritesStore()))
}
