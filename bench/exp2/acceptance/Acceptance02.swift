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

private final class AccStubProtocol: URLProtocol {
    static var response: (status: Int, body: Data)?
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        guard let r = Self.response, let url = request.url,
              let http = HTTPURLResponse(url: url, statusCode: r.status, httpVersion: "HTTP/1.1",
                                         headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: r.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("Acceptance 02: networking", .serialized)
struct Acceptance02Tests {
    private let config = APIConfiguration(apiKey: "TESTKEY")

    private func parts(_ endpoint: Endpoint) throws -> (host: String?, path: String, query: [String: String]) {
        let request = try endpoint.urlRequest(configuration: config)
        let url = try #require(request.url)
        let comps = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        var query: [String: String] = [:]
        for item in comps.queryItems ?? [] { query[item.name] = item.value }
        return (comps.host, comps.path, query)
    }

    private func session() -> URLSession {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [AccStubProtocol.self]
        return URLSession(configuration: cfg)
    }

    private func client(status: Int, body: Data) -> TMDBClient {
        AccStubProtocol.response = (status, body)
        AccStubProtocol.lastRequest = nil
        return TMDBClient(session: session(), configuration: config)
    }

    @Test func popularRequest() throws {
        let p = try parts(.popular(page: 2))
        #expect(p.host == "api.themoviedb.org")
        #expect(p.path.hasSuffix("/movie/popular"))
        #expect(p.query["api_key"] == "TESTKEY")
        #expect(p.query["language"] == "en-US")
        #expect(p.query["page"] == "2")
    }

    @Test func searchRequest() throws {
        let p = try parts(.search(query: "the matrix", page: 1))
        #expect(p.path.hasSuffix("/search/movie"))
        #expect(p.query["query"] == "the matrix")
        #expect(p.query["page"] == "1")
        #expect(p.query["api_key"] == "TESTKEY")
    }

    @Test func detailAndCreditsRequests() throws {
        let d = try parts(.movieDetail(id: 27205))
        #expect(d.path.hasSuffix("/movie/27205"))
        #expect(d.query["api_key"] == "TESTKEY")
        let c = try parts(.credits(movieID: 27205))
        #expect(c.path.hasSuffix("/movie/27205/credits"))
        #expect(c.query["api_key"] == "TESTKEY")
    }

    @Test func endpointsAreEquatable() {
        #expect(Endpoint.popular(page: 1) == Endpoint.popular(page: 1))
        #expect(Endpoint.popular(page: 1) != Endpoint.popular(page: 2))
    }

    @Test func configurationFromEnvironment() throws {
        let c = try APIConfiguration.load(environment: ["TMDB_API_KEY": "ENVKEY"])
        #expect(c.apiKey == "ENVKEY")
        #expect(c.baseURL == TMDBApp.apiBaseURL)
    }

    @Test func missingKeyThrows() {
        do {
            _ = try APIConfiguration.load(environment: [:])
            Issue.record("expected APIError.missingAPIKey")
        } catch let error as APIError {
            guard case .missingAPIKey = error else { Issue.record("got \(error)"); return }
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test func clientDecodesSuccess() async throws {
        let c = client(status: 200, body: try accData("popular_page1"))
        let page = try await c.send(.popular(page: 1), as: PagedResponse<Movie>.self)
        #expect(page.results.count == 5)
        let sent = try #require(AccStubProtocol.lastRequest?.url?.absoluteString)
        #expect(sent.contains("api_key=TESTKEY"))
    }

    @Test func clientMapsHTTPError() async throws {
        let c = client(status: 401, body: try accData("error_401"))
        do {
            _ = try await c.send(.popular(page: 1), as: PagedResponse<Movie>.self)
            Issue.record("expected APIError.httpStatus")
        } catch let error as APIError {
            guard case .httpStatus(let code, let message) = error else { Issue.record("got \(error)"); return }
            #expect(code == 401)
            #expect(message?.contains("Invalid API key") == true)
        }
    }

    @Test func clientMapsDecodingError() async throws {
        let c = client(status: 200, body: Data(#"{"unexpected": true}"#.utf8))
        do {
            _ = try await c.send(.popular(page: 1), as: PagedResponse<Movie>.self)
            Issue.record("expected APIError.decoding")
        } catch let error as APIError {
            guard case .decoding = error else { Issue.record("got \(error)"); return }
        }
    }

    @Test func clientWithoutKeyThrowsMissingAPIKey() async throws {
        unsetenv("TMDB_API_KEY")
        AccStubProtocol.response = (200, try accData("popular_page1"))
        let c = TMDBClient(session: session(), configuration: nil)
        do {
            _ = try await c.send(.popular(page: 1), as: PagedResponse<Movie>.self)
            Issue.record("expected APIError.missingAPIKey")
        } catch let error as APIError {
            guard case .missingAPIKey = error else { Issue.record("got \(error)"); return }
        }
    }
}
