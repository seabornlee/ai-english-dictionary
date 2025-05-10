import Foundation

public class TextValidation {
    public static func isValidEnglishWord(_ text: String) -> Bool {
        // Remove any whitespace and newlines
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty or whitespace-only strings
        if trimmedText.isEmpty {
            return false
        }
        
        // Check if it's a URL
        if trimmedText.hasPrefix("http://") || trimmedText.hasPrefix("https://") || trimmedText.hasPrefix("www.") {
            return false
        }
        
        // Split into words and validate each word
        let words = trimmedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Check if any word contains invalid characters or matches code patterns
        for word in words {
            // Check if it contains only letters and basic punctuation
            let validCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "'-"))
            let invalidCharacters = CharacterSet(charactersIn: word).subtracting(validCharacters)
            
            if !invalidCharacters.isEmpty {
                return false
            }
            
            // Common English words that happen to be in camelCase
            let allowedCamelCaseWords = ["camelCase", "iPhone", "iPad", "iMac", "iPod", "eBay", "eMail", "eBook"]
            if allowedCamelCaseWords.contains(word) {
                continue
            }
            
            // Check if it matches code-like patterns
            let codePatterns = [
                #"[a-zA-Z0-9_]+\([^)]*\)"#,  // Function calls
                #"^[a-zA-Z_][a-zA-Z0-9_]*$"#, // Variable names with underscore
                #"^[A-Z][a-zA-Z0-9_]*$"#,     // Class names with underscore
                #"^[a-z][a-zA-Z0-9_]*$"#,     // Method names with underscore
                #"^[A-Z_][A-Z0-9_]*$"#,       // Constants with underscore
                #"^[a-z_][a-z0-9_]*$"#,       // Variables with underscore
                #"^[a-z]+[A-Z][a-zA-Z]*$"#,   // camelCase
                #"^[A-Z][a-z]+[A-Z][a-zA-Z]*$"# // PascalCase
            ]
            
            // Check code patterns if the word contains underscores, parentheses, or camelCase/PascalCase
            if word.contains("_") || word.contains("(") || 
               word.range(of: #"^[a-z]+[A-Z][a-zA-Z]*$"#, options: .regularExpression) != nil ||
               word.range(of: #"^[A-Z][a-z]+[A-Z][a-zA-Z]*$"#, options: .regularExpression) != nil {
                for pattern in codePatterns {
                    if word.range(of: pattern, options: .regularExpression) != nil {
                        return false
                    }
                }
            }
        }
        
        return true
    }
} 