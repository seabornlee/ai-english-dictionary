import AppKit
import Foundation

enum StitchMenuBarTab: Int, CaseIterable, Identifiable {
    case define
    case favorites
    case history

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .define:
            return "Define"
        case .favorites:
            return "Favorites"
        case .history:
            return "History"
        }
    }
}

enum StitchLibraryTab: String, CaseIterable, Identifiable {
    case vocabulary
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vocabulary:
            return "Vocabulary"
        case .history:
            return "History"
        }
    }
}

enum StitchUIHelpers {
    private static let stopWords: Set<String> = [
        "about", "after", "again", "among", "being", "bright", "could",
        "every", "first", "found", "great", "light", "other", "should",
        "their", "there", "these", "those", "under", "using", "which",
        "while", "without"
    ]

    static func keywordChips(from definition: String, excluding excludedWord: String) -> [String] {
        var seen = Set<String>()
        let normalizedExcludedWord = excludedWord.lowercased()

        return definition
            .components(separatedBy: CharacterSet.letters.inverted)
            .map { $0.lowercased() }
            .filter { token in
                token.count >= 5 &&
                    token != normalizedExcludedWord &&
                    !stopWords.contains(token) &&
                    seen.insert(token).inserted
            }
            .prefix(3)
            .map { token in
                token.prefix(1).uppercased() + token.dropFirst()
            }
    }

    static func historyDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    static func exampleSentence(for word: Word?) -> String {
        guard let word else {
            return "Search for a word to see a quick example in context."
        }

        return listeningSentences(for: word).first ?? "The \(word.term.lowercased()) entry is ready for your next review session."
    }

    static func listeningSentences(for word: Word) -> [String] {
        let cleanedSentences = word.exampleSentences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !cleanedSentences.isEmpty {
            return cleanedSentences
        }

        let fallbackDefinition = word.definition.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallbackDefinition.isEmpty ? [] : [fallbackDefinition]
    }

    static func listeningSectionTitle(for word: Word) -> String {
        let hasExamples = word.exampleSentences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains { !$0.isEmpty }

        return hasExamples ? "Example Sentences" : "Definition to Hear"
    }

    static func pronunciationLabel(for word: Word) -> String {
        if let pronunciation = word.pronunciation?.trimmingCharacters(in: .whitespacesAndNewlines), !pronunciation.isEmpty {
            return "/\(pronunciation)/"
        }

        return "Pronunciation unavailable"
    }

    static func trimmedDefinition(_ definition: String, limit: Int) -> String {
        guard definition.count > limit else {
            return definition
        }

        let index = definition.index(definition.startIndex, offsetBy: limit)
        return definition[..<index].trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}

protocol SpeechEngine {
    var isSpeaking: Bool { get }
    func startSpeaking(_ text: String) -> Bool
    func stopSpeaking()
}

extension NSSpeechSynthesizer: SpeechEngine {}

final class SpeechCoordinator: NSObject, ObservableObject, NSSpeechSynthesizerDelegate {
    static let shared = SpeechCoordinator()

    @Published private(set) var speakingText: String?

    private let synthesizer: SpeechEngine

    init(engine: SpeechEngine = NSSpeechSynthesizer()) {
        synthesizer = engine
        super.init()
        if let nativeSynthesizer = synthesizer as? NSSpeechSynthesizer {
            nativeSynthesizer.delegate = self
        }
    }

    func speak(_ text: String) {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty else {
            return
        }

        if speakingText == normalizedText, synthesizer.isSpeaking {
            synthesizer.stopSpeaking()
            speakingText = nil
            return
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking()
        }

        if synthesizer.startSpeaking(normalizedText) {
            speakingText = normalizedText
        } else {
            speakingText = nil
        }
    }

    func speechSynthesizer(_ sender: NSSpeechSynthesizer, didFinishSpeaking finishedSpeaking: Bool) {
        DispatchQueue.main.async {
            self.speakingText = nil
        }
    }
}
