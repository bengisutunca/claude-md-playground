import Foundation
import Testing
@testable import TMDBApp

@Suite("Model decoding")
struct ModelDecodingTests {
    private func decode<T: Decodable>(_ type: T.Type, _ name: String) throws -> T {
        try JSONDecoder.tmdb.decode(type, from: Fixture.data(name))
    }

    @Test func popularPage1() throws {
        let page = try decode(PagedResponse<Movie>.self, "popular_page1")
        #expect(page.page == 1)
        #expect(page.totalPages == 2)
        #expect(page.totalResults == 7)
        #expect(page.results.count == 5)
        let inception = try #require(page.results.first)
        #expect(inception.id == 27205)
        #expect(inception.genreIDs == [28, 878, 12])
        #expect(inception.year == "2010")
        #expect(inception.ratingText == "8.4")
        #expect(inception.posterPath == "/inception.jpg")
    }

    @Test func nullImagePathsDecodeAsNil() throws {
        let page = try decode(PagedResponse<Movie>.self, "popular_page1")
        let shawshank = try #require(page.results.first(where: { $0.title == "The Shawshank Redemption" }))
        #expect(shawshank.backdropPath == nil)
        #expect(shawshank.posterPath == "/shawshank.jpg")
        let fightClub = try #require(page.results.first(where: { $0.title == "Fight Club" }))
        #expect(fightClub.posterPath == nil)
        #expect(fightClub.backdropPath == "/fight_club_bg.jpg")
    }

    @Test func popularPage2EmptyReleaseDate() throws {
        let page = try decode(PagedResponse<Movie>.self, "popular_page2")
        #expect(page.page == 2)
        #expect(page.results.count == 2)
        let parasite = try #require(page.results.first(where: { $0.title == "Parasite" }))
        #expect(parasite.releaseDate == nil)
        #expect(parasite.year == nil)
        let spirited = try #require(page.results.first(where: { $0.title == "Spirited Away" }))
        #expect(spirited.year == "2001")
    }

    @Test func movieDetail() throws {
        let d = try decode(MovieDetail.self, "movie_detail_27205")
        #expect(d.id == 27205)
        #expect(d.runtime == 148)
        #expect(d.tagline == "Your mind is the scene of the crime.")
        #expect(d.status == "Released")
        #expect(d.genres.map(\.name) == ["Action", "Science Fiction", "Adventure"])
        #expect(d.year == "2010")
        #expect(d.ratingText == "8.4")
    }

    @Test func movieCredits() throws {
        let c = try decode(Credits.self, "movie_credits_27205")
        #expect(c.id == 27205)
        #expect(c.cast.count == 4)
        #expect(c.cast[0].name == "Leonardo DiCaprio")
        #expect(c.cast[0].character == "Cobb")
        #expect(c.cast[2].profilePath == nil)
        #expect(c.crew.first?.job == "Director")
    }

    @Test func ratingTextUsesOneDecimal() {
        #expect(Movie(id: 1, title: "A", voteAverage: 7).ratingText == "7.0")
        #expect(Movie(id: 1, title: "A", voteAverage: 8.44).ratingText == "8.4")
    }
}
