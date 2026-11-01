import Foundation
import Testing
@testable import TMDBApp

@Suite("Model decoding")
struct ModelDecodingTests {
    @Test func popularPage1() throws {
        let page = try JSONDecoder.tmdb.decode(PagedResponse<Movie>.self, from: Fixture.data("popular_page1"))
        #expect(page.page == 1)
        #expect(page.totalPages == 2)
        #expect(page.totalResults == 7)
        #expect(!page.results.isEmpty)

        let inception = try #require(page.results.first)
        #expect(inception.id == 27205)
        #expect(inception.title == "Inception")
        #expect(inception.posterPath == "/inception.jpg")
        #expect(inception.backdropPath == "/inception_bg.jpg")
        #expect(inception.genreIDs == [28, 878, 12])
        #expect(inception.voteCount == 37000)
        #expect(inception.year == "2010")
        #expect(inception.ratingText == "8.4")
    }

    @Test func nullImagePaths() throws {
        let page = try JSONDecoder.tmdb.decode(PagedResponse<Movie>.self, from: Fixture.data("popular_page1"))
        #expect(page.results.contains(where: { $0.backdropPath == nil }))
        #expect(page.results.contains(where: { $0.posterPath == nil }))
    }

    @Test func emptyReleaseDateIsNil() throws {
        let page = try JSONDecoder.tmdb.decode(PagedResponse<Movie>.self, from: Fixture.data("popular_page2"))
        #expect(page.page == 2)
        let missing = page.results.filter { $0.releaseDate == nil }
        #expect(!missing.isEmpty)
        #expect(missing.allSatisfy { $0.year == nil })
    }

    @Test func movieDetail() throws {
        let detail = try JSONDecoder.tmdb.decode(MovieDetail.self, from: Fixture.data("movie_detail_27205"))
        #expect(detail.id == 27205)
        #expect(detail.runtime == 148)
        #expect(detail.tagline == "Your mind is the scene of the crime.")
        #expect(detail.status == "Released")
        #expect(detail.genres.map(\.name) == ["Action", "Science Fiction", "Adventure"])
        #expect(detail.year == "2010")
        #expect(detail.ratingText == "8.4")
    }

    @Test func credits() throws {
        let credits = try JSONDecoder.tmdb.decode(Credits.self, from: Fixture.data("movie_credits_27205"))
        #expect(credits.id == 27205)
        #expect(credits.cast.count == 4)
        #expect(credits.cast[0].name == "Leonardo DiCaprio")
        #expect(credits.cast[0].character == "Cobb")
        #expect(credits.cast[2].profilePath == nil)
        #expect(credits.crew.first?.job == "Director")
    }

    @Test func ratingTextOneDecimal() {
        #expect(Movie(id: 1, title: "A", voteAverage: 7).ratingText == "7.0")
        #expect(Movie(id: 1, title: "A", voteAverage: 8.449).ratingText == "8.4")
    }
}
