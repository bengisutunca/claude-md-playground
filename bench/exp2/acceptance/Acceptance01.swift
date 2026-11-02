import Foundation
import Testing
@testable import TMDBApp

// Hidden acceptance test: copied in by the benchmark harness after the session ends.
// The agent never sees this file. Self-contained: it does not use any test helper the agent wrote.

private struct AccMissingFixture: Error { let name: String }

private func accData(_ name: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
        throw AccMissingFixture(name: name)
    }
    return try Data(contentsOf: url)
}

@Suite("Acceptance 01: models")
struct Acceptance01Tests {
    private func page(_ name: String) throws -> PagedResponse<Movie> {
        try JSONDecoder.tmdb.decode(PagedResponse<Movie>.self, from: accData(name))
    }

    @Test func pageMetadata() throws {
        let p = try page("popular_page1")
        #expect(p.page == 1)
        #expect(p.totalPages == 2)
        #expect(p.totalResults == 7)
        #expect(p.results.count == 5)
    }

    @Test func movieFields() throws {
        let results = try page("popular_page1").results
        let m = try #require(results.first)
        #expect(m.id == 27205)
        #expect(m.title == "Inception")
        #expect(m.overview.isEmpty == false)
        #expect(m.posterPath == "/inception.jpg")
        #expect(m.backdropPath == "/inception_bg.jpg")
        #expect(abs(m.voteAverage - 8.4) < 0.0001)
        #expect(m.voteCount == 37000)
        #expect(m.genreIDs == [28, 878, 12])
        #expect(m.releaseDate != nil)
        #expect(m.year == "2010")
        #expect(m.ratingText == "8.4")
    }

    @Test func nullImagePathsDecodeAsNil() throws {
        let results = try page("popular_page1").results
        let shawshank = try #require(results.first(where: { $0.id == 278 }))
        #expect(shawshank.backdropPath == nil)
        #expect(shawshank.posterPath == "/shawshank.jpg")
        let fightClub = try #require(results.first(where: { $0.id == 550 }))
        #expect(fightClub.posterPath == nil)
    }

    @Test func emptyReleaseDateDecodesAsNil() throws {
        let results = try page("popular_page2").results
        let parasite = try #require(results.first(where: { $0.id == 496243 }))
        #expect(parasite.releaseDate == nil)
        #expect(parasite.year == nil)
        let spirited = try #require(results.first(where: { $0.id == 129 }))
        #expect(spirited.year == "2001")
    }

    @Test func ratingTextHasOneDecimal() throws {
        let results = try page("popular_page1").results
        #expect(results.map(\.ratingText) == ["8.4", "8.4", "8.5", "8.7", "8.4"])
    }

    @Test func moviesAreHashableAndIdentifiable() throws {
        let results = try page("popular_page1").results
        #expect(Set(results).count == 5)
        #expect(results.map(\.id) == [27205, 157336, 155, 278, 550])
    }

    @Test func movieDetail() throws {
        let d = try JSONDecoder.tmdb.decode(MovieDetail.self, from: accData("movie_detail_27205"))
        #expect(d.id == 27205)
        #expect(d.title == "Inception")
        #expect(d.runtime == 148)
        #expect(d.tagline == "Your mind is the scene of the crime.")
        #expect(d.status == "Released")
        #expect(d.genres.map(\.name) == ["Action", "Science Fiction", "Adventure"])
        #expect(d.genres.map(\.id) == [28, 878, 12])
        #expect(d.year == "2010")
    }

    @Test func credits() throws {
        let c = try JSONDecoder.tmdb.decode(Credits.self, from: accData("movie_credits_27205"))
        #expect(c.id == 27205)
        #expect(c.cast.count == 4)
        #expect(c.cast.first?.name == "Leonardo DiCaprio")
        #expect(c.cast.first?.character == "Cobb")
        #expect(c.cast.map(\.order) == [0, 1, 2, 3])
        #expect(c.cast[2].profilePath == nil)
        #expect(c.cast[0].profilePath == "/dicaprio.jpg")
        #expect(c.crew.count == 1)
        #expect(c.crew.first?.name == "Christopher Nolan")
        #expect(c.crew.first?.job == "Director")
        #expect(c.crew.first?.department == "Directing")
    }
}
