import SwiftUI

struct MovieRowView: View {
    let movie: Movie

    var body: some View {
        HStack(spacing: 12) {
            PosterImage(path: movie.posterPath, size: .w185)
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
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
