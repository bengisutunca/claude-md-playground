import SwiftUI

struct MovieRowView: View {
    let movie: Movie
    var imageURLBuilder = ImageURLBuilder()

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(url: imageURLBuilder.url(path: movie.posterPath, size: .w185))
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title).font(.headline).lineLimit(2)
                if let year = movie.year {
                    Text(year).font(.subheadline).foregroundStyle(.secondary)
                }
                Label(movie.ratingText, systemImage: "star.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// Plain list style on iOS. Platform default elsewhere.
    @ViewBuilder
    func plainListStyle() -> some View {
        #if os(iOS)
        listStyle(.plain)
        #else
        self
        #endif
    }
}

#Preview {
    MovieRowView(movie: PreviewMovieService.movies[0]).padding()
}
