import SwiftUI

struct MovieRowView: View {
    let movie: Movie
    var imageURLBuilder = ImageURLBuilder()

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: imageURLBuilder.url(path: movie.posterPath, size: .w185)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "film").foregroundStyle(.secondary)
                    }
                }
            }
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
