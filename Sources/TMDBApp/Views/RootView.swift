import SwiftUI

public struct RootView: View {
    private let dependencies: AppDependencies
    @State private var listViewModel: MovieListViewModel
    @State private var searchViewModel: SearchViewModel

    public init() {
        self.init(dependencies: .live())
    }

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _listViewModel = State(initialValue: dependencies.makeMovieListViewModel())
        _searchViewModel = State(initialValue: dependencies.makeSearchViewModel())
    }

    public var body: some View {
        TabView {
            NavigationStack {
                MovieListView(viewModel: listViewModel, service: dependencies.movieService)
            }
            .tabItem { Label("Popular", systemImage: "flame") }

            NavigationStack {
                SearchView(viewModel: searchViewModel, service: dependencies.movieService)
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }

            NavigationStack {
                FavoritesView(service: dependencies.movieService)
            }
            .tabItem { Label("Favorites", systemImage: "heart") }
        }
        .environment(dependencies.favorites)
    }
}

#Preview { RootView(dependencies: .preview) }
