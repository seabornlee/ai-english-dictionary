import Foundation

struct Word: Identifiable, Codable, Equatable {
    var id: String { term }
    let term: String
    let definition: String
    let pronunciation: String?
    let partOfSpeech: String?
    let exampleSentences: [String]
    let timestamp: Date

    init(
        term: String,
        definition: String,
        pronunciation: String? = nil,
        partOfSpeech: String? = nil,
        exampleSentences: [String] = [],
        timestamp: Date
    ) {
        self.term = term
        self.definition = definition
        self.pronunciation = pronunciation
        self.partOfSpeech = partOfSpeech
        self.exampleSentences = exampleSentences
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case term
        case definition
        case pronunciation
        case partOfSpeech
        case exampleSentences
        case timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        term = try container.decode(String.self, forKey: .term)
        definition = try container.decode(String.self, forKey: .definition)
        pronunciation = try container.decodeIfPresent(String.self, forKey: .pronunciation)
        partOfSpeech = try container.decodeIfPresent(String.self, forKey: .partOfSpeech)
        exampleSentences = try container.decodeIfPresent([String].self, forKey: .exampleSentences) ?? []
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }

    static func == (lhs: Word, rhs: Word) -> Bool {
        return lhs.term == rhs.term &&
            lhs.definition == rhs.definition &&
            lhs.pronunciation == rhs.pronunciation &&
            lhs.partOfSpeech == rhs.partOfSpeech &&
            lhs.exampleSentences == rhs.exampleSentences &&
            lhs.timestamp == rhs.timestamp
    }
}
