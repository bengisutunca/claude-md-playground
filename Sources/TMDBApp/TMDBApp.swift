import Foundation

/// Namespace for the TMDB client app.
///
/// Layers (MVVM):
/// - `Models/`      Codable domain types decoded from TMDB responses
/// - `Networking/`  Endpoints, HTTP client, API errors
/// - `Services/`    Protocol-based data access used by view models
/// - `ViewModels/`  `@Observable`, `@MainActor` state holders
/// - `Views/`       SwiftUI screens (no business logic)
public enum TMDBApp {
    public static let apiBaseURL = URL(string: "https://api.themoviedb.org/3")!
    public static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p")!
}
