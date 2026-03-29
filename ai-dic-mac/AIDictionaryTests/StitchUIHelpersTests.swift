@testable import AIDictionary
import XCTest

final class StitchUIHelpersTests: XCTestCase {
    func testListeningSectionTitleUsesExamplesWhenAvailable() {
        let word = Word(
            term: "luminous",
            definition: "Giving off a soft, clear light.",
            pronunciation: "ˈluːmɪnəs",
            partOfSpeech: "adjective",
            exampleSentences: ["The hallway became luminous at sunrise."],
            timestamp: Date()
        )

        XCTAssertEqual(StitchUIHelpers.listeningSectionTitle(for: word), "Example Sentences")
    }

    func testListeningSectionTitleFallsBackWhenOnlyDefinitionIsAvailable() {
        let word = Word(
            term: "luminous",
            definition: "Giving off a soft, clear light.",
            pronunciation: nil,
            partOfSpeech: nil,
            exampleSentences: [],
            timestamp: Date()
        )

        XCTAssertEqual(StitchUIHelpers.listeningSectionTitle(for: word), "Definition to Hear")
    }

    func testSpeechCoordinatorDoesNotKeepSpeakingTextWhenPlaybackFailsToStart() {
        let coordinator = SpeechCoordinator(
            engine: MockSpeechEngine(
                isSpeaking: false,
                startHandler: { _ in false },
                stopHandler: {}
            )
        )

        coordinator.speak("luminous")

        XCTAssertNil(coordinator.speakingText)
    }

    func testKeywordChipsSelectMeaningfulTermsFromDefinition() {
        let chips = StitchUIHelpers.keywordChips(
            from: "Radiating or reflecting light; shining; bright. Very brilliant; intellectual.",
            excluding: "luminous"
        )

        XCTAssertEqual(chips, ["Radiating", "Reflecting", "Shining"])
    }

    func testKeywordChipsDeduplicateAndCapAtThree() {
        let chips = StitchUIHelpers.keywordChips(
            from: "Brilliant brilliant radiant vivid radiant luminous reflective",
            excluding: "luminous"
        )

        XCTAssertEqual(chips, ["Brilliant", "Radiant", "Vivid"])
    }

    func testHistoryDateStringUsesCompactMonthDayYearFormat() throws {
        let components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2026,
            month: 3,
            day: 15
        )

        let date = try XCTUnwrap(components.date)

        XCTAssertEqual(StitchUIHelpers.historyDateString(from: date), "Mar 15, 2026")
    }
}

private struct MockSpeechEngine: SpeechEngine {
    var isSpeaking: Bool
    let startHandler: (String) -> Bool
    let stopHandler: () -> Void

    func startSpeaking(_ text: String) -> Bool {
        startHandler(text)
    }

    func stopSpeaking() {
        stopHandler()
    }
}
