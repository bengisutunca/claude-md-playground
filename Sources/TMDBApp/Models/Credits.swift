struct CastMember: Identifiable, Hashable, Sendable, Decodable {
    let id: Int
    let name: String
    let character: String?
    let order: Int?
    let profilePath: String?
}

struct CrewMember: Identifiable, Hashable, Sendable, Decodable {
    let id: Int
    let name: String
    let job: String?
    let department: String?
    let profilePath: String?
}

struct Credits: Identifiable, Hashable, Sendable, Decodable {
    let id: Int
    let cast: [CastMember]
    let crew: [CrewMember]
}
