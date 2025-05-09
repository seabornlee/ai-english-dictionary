import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    case noData
}

class APIService {
    static let shared = APIService()
    
    private init() {}
    
    // Replace with your server URL
    private let baseURL = "http://localhost:3000"
    
    func lookupWord(_ word: String, unknownWords: [String] = []) async throws -> Word {
        let url = URL(string: "\(baseURL)/api/dictionary/define")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "word": word,
            "unknownWords": unknownWords
        ]
        
        print("body: \(body)")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("error: \(error)")
            throw APIError.networkError(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            let result = try decoder.decode(Word.self, from: data)
            return result
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    func toggleFavorite(_ word: Word) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/favorites") else {
            throw APIError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "term": word.term,
            "definition": word.definition
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw APIError.networkError(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let isFavorite = json["isFavorite"] as? Bool {
                return isFavorite
            } else {
                throw APIError.noData
            }
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func getFavorites() async throws -> [Word] {
        guard let url = URL(string: "\(baseURL)/favorites") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            let favorites = try decoder.decode([Word].self, from: data)
            return favorites
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func getVocabulary() async throws -> [Word] {
        guard let url = URL(string: "\(baseURL)/vocabulary") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            let vocabulary = try decoder.decode([Word].self, from: data)
            return vocabulary
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func addToVocabulary(_ word: Word) async throws {
        guard let url = URL(string: "\(baseURL)/vocabulary") else {
            throw APIError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "term": word.term,
            "definition": word.definition
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw APIError.networkError(error)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func removeFromVocabulary(_ word: Word) async throws {
        guard let encodedTerm = word.term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/vocabulary/\(encodedTerm)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func getSearchHistory() async throws -> [Word] {
        guard let url = URL(string: "\(baseURL)/history") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            let history = try decoder.decode([Word].self, from: data)
            return history
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func clearSearchHistory() async throws {
        guard let url = URL(string: "\(baseURL)/history") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
} 