import SwiftUI

struct MovieDetailView: View {
    @State private var viewModel: MovieDetailViewModel
    var imageURLBuilder = ImageURLBuilder()

    init(viewModel: MovieDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            message("No details available.", retry: false)
        case .failed(let text):
            message(text, retry: true)
        case .loaded(let content):
            ScrollView { loaded(content) }
        }
    }

    private func loaded(_ content: MovieDetailContent) -> some View {
        let detail = content.detail
        return VStack(alignment: .leading, spacing: 16) {
            backdrop(detail.backdropPath)
            HStack(alignment: .bottom, spacing: 12) {
                image(detail.posterPath, size: .w342)
                    .frame(width: 100, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.title).font(.title2.bold())
                    if let year = content.releaseYear {
                        Text(year).foregroundStyle(.secondary)
                    }
                    Label(detail.ratingText, systemImage: "star.fill").foregroundStyle(.orange)
                    if let runtime = content.runtimeText {
                        Text(runtime).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                if let tagline = detail.tagline, !tagline.isEmpty {
                    Text(tagline).italic().foregroundStyle(.secondary)
                }
                if !content.genresText.isEmpty {
                    Text(content.genresText).font(.subheadline)
                }
                if !detail.overview.isEmpty {
                    Text("Overview").font(.headline)
                    Text(detail.overview)
                }
                if !content.directors.isEmpty {
                    Text("Director").font(.headline)
                    Text(content.directorsText)
                }
            }
            .padding(.horizontal)

            if !content.cast.isEmpty {
                Text("Cast").font(.headline).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(content.cast) { member in
                            VStack(spacing: 4) {
                                image(member.profilePath, size: .w185)
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
        }
        .padding(.bottom)
    }

    private func backdrop(_ path: String?) -> some View {
        image(path, size: .w780)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipped()
    }

    private func image(_ path: String?, size: ImageURLBuilder.Size) -> some View {
        AsyncImage(url: imageURLBuilder.url(path: path, size: size)) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: "film").foregroundStyle(.secondary)
            }
        }
    }

    private func message(_ text: String, retry: Bool) -> some View {
        VStack(spacing: 12) {
            Text(text).multilineTextAlignment(.center).foregroundStyle(.secondary)
            if retry {
                Button("Try Again") { Task { await viewModel.retry() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
