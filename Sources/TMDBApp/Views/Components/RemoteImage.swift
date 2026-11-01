import SwiftUI

/// Async image that fills its frame. Shows a symbol placeholder while loading, on failure or without a URL.
struct RemoteImage: View {
    let url: URL?
    var placeholder = "film"

    var body: some View {
        AsyncImage(url: url) { phase in
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

#Preview {
    RemoteImage(url: nil).frame(width: 60, height: 90)
}
