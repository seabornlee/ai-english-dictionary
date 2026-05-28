@testable import AIDictionary
import XCTest

final class TextValidationTests: XCTestCase {
    func testValidEnglishWords() {
        // Test single words
        XCTAssertTrue(TextValidation.isValidEnglishWord("hello"))
        XCTAssertTrue(TextValidation.isValidEnglishWord("world"))
        XCTAssertTrue(TextValidation.isValidEnglishWord("don't"))
        XCTAssertTrue(TextValidation.isValidEnglishWord("well-being"))
        XCTAssertTrue(TextValidation.isValidEnglishWord("copy"))
        XCTAssertTrue(TextValidation.isValidEnglishWord("camelCase"))

        // Test multiple words
        XCTAssertTrue(TextValidation.isValidEnglishWord("hello world"))
        XCTAssertTrue(TextValidation.isValidEnglishWord("don't worry"))
        XCTAssertTrue(TextValidation.isValidEnglishWord("well-being matters"))
    }

    func testInvalidURLs() {
        XCTAssertFalse(TextValidation.isValidEnglishWord("http://example.com"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("https://example.com"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("www.example.com"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("http://"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("https://"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("www."))
    }

    func testInvalidCodePatterns() {
        // Function calls
        XCTAssertFalse(TextValidation.isValidEnglishWord("function()"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("getData()"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("processUser(user)"))

        // Variable names
        XCTAssertFalse(TextValidation.isValidEnglishWord("userName"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("total_count"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("_privateVar"))

        // Class names
        XCTAssertFalse(TextValidation.isValidEnglishWord("UserProfile"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("DataManager"))

        // Method names
        XCTAssertFalse(TextValidation.isValidEnglishWord("getUserData"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("processRequest"))

        // Constants
        XCTAssertFalse(TextValidation.isValidEnglishWord("MAX_COUNT"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("API_KEY"))

        // Variables
        XCTAssertFalse(TextValidation.isValidEnglishWord("user_name"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("total_count"))
    }

    func testInvalidCharacters() {
        XCTAssertFalse(TextValidation.isValidEnglishWord("hello123"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("AIDictionaryPackageTests.xctest"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("user@example.com"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("price$99"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("hello.world"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("hello_world"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("hello+world"))
    }

    func testWhitespaceHandling() {
        XCTAssertTrue(TextValidation.isValidEnglishWord("  hello  "))
        XCTAssertTrue(TextValidation.isValidEnglishWord("\thello\t"))
        XCTAssertTrue(TextValidation.isValidEnglishWord("\nhello\n"))
        XCTAssertTrue(TextValidation.isValidEnglishWord("  hello world  "))
    }

    func testEmptyAndSpecialCases() {
        XCTAssertFalse(TextValidation.isValidEnglishWord(""))
        XCTAssertFalse(TextValidation.isValidEnglishWord(" "))
        XCTAssertFalse(TextValidation.isValidEnglishWord("\t"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("\n"))
        XCTAssertFalse(TextValidation.isValidEnglishWord("   "))
    }
}
