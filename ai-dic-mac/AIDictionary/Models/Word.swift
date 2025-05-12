import Foundation

struct Word: Identifiable, Codable, Equatable {
    var id: String { term }
    let term: String
    let definition: String
    let timestamp: Date

    static func == (lhs: Word, rhs: Word) -> Bool {
        return lhs.term == rhs.term &&
            lhs.definition == rhs.definition &&
            lhs.timestamp == rhs.timestamp
    }
}
