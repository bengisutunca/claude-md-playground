import SwiftUI

struct MovieDetailView: View {
    @State private var viewModel: MovieDetailViewModel
    var imageURLBuilder = ImageURLBuilder()
    /// Injected with `.environment(_:)`. Heart button hidden when absent.
    @Environment(FavoritesViewModel.self) private var favorites: FavoritesViewModel?

    init(viewModel: MovieDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if let favorites, case .loaded(let content) = viewModel.state {
                    let movie = Movie(detail: content.detail)
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            favorites.toggle(movie)
                        } label: {
                            Image(systemName: favorites.isFavorite(movie) ? "heart.fill" : "heart")
                        }
                        .accessibilityLabel(
                            favorites.isFavorite(movie) ? "Remove from favorites" : "Add to favorites")
                    }
                }
            }
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .empty:
            Text("No details available.").foregroundStyle(.secondary)
        case .failed(let message):
            VStack(spacing: 12) {
                Text(message).multilineTextAlignment(.center)
                Button("Retry") { Task { await viewModel.load() } }
            }
            .padding()
        case .loaded(let content):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    backdrop(content.detail)
                    header(content)
                    if !content.detail.overview.isEmpty {
                        section("Overview") { Text(content.detail.overview).padding(.horizontal) }
                    }
                    if !content.directors.isEmpty {
                        section(content.directors.count > 1 ? "Directors" : "Director") {
                            Text(content.directors.map(\.name).joined(separator: ", "))
                                .padding(.horizontal)
                        }
                    }
                    if !content.cast.isEmpty {
                        section("Cast") { castList(content.cast) }
                    }
                }
                .padding(.bottom)
            }
        }
    }

    private func backdrop(_ detail: MovieDetail) -> some View {
        image(path: detail.backdropPath, size: .w780, placeholder: "film")
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .clipped()
    }

    private func header(_ content: MovieDetailContent) -> some View {
        let detail = content.detail
        let meta = [content.releaseYear, content.runtimeText].compactMap { $0 }
        return HStack(alignment: .top, spacing: 12) {
            image(path: detail.posterPath, size: .w342, placeholder: "film")
                .frame(width: 100, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 6) {
                Text(detail.title).font(.title2.bold())
                if let tagline = detail.tagline, !tagline.isEmpty {
                    Text(tagline).font(.subheadline).italic().foregroundStyle(.secondary)
                }
                Label(detail.ratingText, systemImage: "star.fill")
                    .foregroundStyle(.orange)
                if !meta.isEmpty {
                    Text(meta.joined(separator: " · ")).font(.subheadline)
                }
                if !content.genresText.isEmpty {
                    Text(content.genresText).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    private func castList(_ cast: [CastMember]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(cast) { member in
                    VStack(spacing: 4) {
                        image(path: member.profilePath, size: .w185, placeholder: "person")
                            .frame(width: 80, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text(member.name).font(.caption.bold()).lineLimit(2)
                        if let character = member.character, !character.isEmpty {
                            Text(character).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                    .frame(width: 80)
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
        }
    }

    private func section<Body: View>(_ title: String, @ViewBuilder body: () -> Body) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).padding(.horizontal)
            body()
        }
    }

    private func image(path: String?, size: ImageURLBuilder.Size, placeholder: String) -> some View {
        AsyncImage(url: imageURLBuilder.url(path: path, size: size)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: placeholder).foregroundStyle(.secondary)
                }
            }
        }
    }
}
