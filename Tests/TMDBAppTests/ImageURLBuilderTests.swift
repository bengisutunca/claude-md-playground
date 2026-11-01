import Foundation
import Testing
@testable import TMDBApp

@Suite("ImageURLBuilder")
struct ImageURLBuilderTests {
    let builder = ImageURLBuilder()

    @Test(arguments: ImageURLBuilder.Size.allCases)
    func buildsURLForEverySize(size: ImageURLBuilder.Size) {
        let url = builder.url(path: "/abc.jpg", size: size)
        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/\(size.rawValue)/abc.jpg")
    }

    @Test func nilPathReturnsNil() {
        #expect(builder.url(path: nil, size: .w185) == nil)
    }

    @Test func emptyPathReturnsNil() {
        #expect(builder.url(path: "", size: .w342) == nil)
    }

    @Test func pathWithoutLeadingSlashIsNormalized() {
        #expect(builder.url(path: "abc.jpg", size: .w780)?.absoluteString == "https://image.tmdb.org/t/p/w780/abc.jpg")
    }

    @Test func usesAppImageBaseURL() {
        let url = builder.url(path: "/x.png", size: .original)
        #expect(url?.absoluteString.hasPrefix(TMDBApp.imageBaseURL.absoluteString) == true)
    }
}
