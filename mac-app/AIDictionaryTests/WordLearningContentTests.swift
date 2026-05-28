@testable import AIDictionary
import XCTest

final class WordLearningContentTests: XCTestCase {
    func testWordDecodesPronunciationPartOfSpeechAndExampleSentences() throws {
        let json = """
        {
            "term": "luminous",
            "definition": "Giving off a soft, clear light.",
            "pronunciation": "ˈluːmɪnəs",
            "partOfSpeech": "adjective",
            "exampleSentences": [
                "The hallway became luminous at sunrise.",
                "Her luminous smile calmed the room."
            ],
            "timestamp": "2026-03-24T00:00:00.000+0000"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(formatter)

        let word = try decoder.decode(Word.self, from: json)

        XCTAssertEqual(word.pronunciation, "ˈluːmɪnəs")
        XCTAssertEqual(word.partOfSpeech, "adjective")
        XCTAssertEqual(
            word.exampleSentences,
            [
                "The hallway became luminous at sunrise.",
                "Her luminous smile calmed the room.",
            ]
        )
    }

    func testExampleSentenceUsesFirstLearningSentenceWhenAvailable() {
        let word = Word(
            term: "luminous",
            definition: "Giving off a soft, clear light.",
            pronunciation: "ˈluːmɪnəs",
            partOfSpeech: "adjective",
            exampleSentences: ["The hallway became luminous at sunrise."],
            timestamp: Date()
        )

        XCTAssertEqual(
            StitchUIHelpers.exampleSentence(for: word),
            "The hallway became luminous at sunrise."
        )
    }

    func testListeningSentencesFallsBackToDefinitionWhenExamplesMissing() {
        let word = Word(
            term: "luminous",
            definition: "Giving off a soft, clear light.",
            pronunciation: nil,
            partOfSpeech: nil,
            exampleSentences: [],
            timestamp: Date()
        )

        XCTAssertEqual(
            StitchUIHelpers.listeningSentences(for: word),
            ["Giving off a soft, clear light."]
        )
    }
}
