import Foundation
import Testing
@testable import TMDBApp

@Suite("Smoke")
struct SmokeTests {
    @Test func baseURLsAreValid() {
        #expect(TMDBApp.apiBaseURL.host == "api.themoviedb.org")
        #expect(TMDBApp.imageBaseURL.host == "image.tmdb.org")
    }

    @Test func fixturesAreValidJSON() throws {
        for name in ["popular_page1", "popular_page2", "search_inception", "search_empty",
                     "movie_detail_27205", "movie_credits_27205", "error_401"] {
            let data = try Fixture.data(name)
            _ = try JSONSerialization.jsonObject(with: data)
        }
    }
}
