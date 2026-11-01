import SwiftUI

/// Remote TMDB image with a film placeholder; fills its frame.
struct PosterImage: View {
    let path: String?
    let size: ImageURLBuilder.Size
    var imageURLBuilder = ImageURLBuilder()

    var body: some View {
        AsyncImage(url: imageURLBuilder.url(path: path, size: size)) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: "film").foregroundStyle(.secondary)
            }
        }
    }
}
