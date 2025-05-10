import Foundation
import SwiftUI

class WordStore: ObservableObject {
    @Published var favorites: [Word] = []
    @Published var vocabularyList: [Word] = []
    @Published var searchHistory: [Word] = []
    @Published var unknownWords: [String] = []
    
    init() {
        loadData()
    }
    
    func loadData() {
        Task {
            await loadFavorites()
            await loadVocabulary()
            await loadHistory()
            await loadUnknownWords()
        }
    }
    
    func addToFavorites(_ word: Word) {
        Task {
            do {
                let isFavorite = try await APIService.shared.toggleFavorite(word)
                
                DispatchQueue.main.async {
                    if isFavorite {
                        if !self.favorites.contains(where: { $0.term == word.term }) {
                            self.favorites.append(word)
                        }
                    } else {
                        self.favorites.removeAll(where: { $0.term == word.term })
                    }
                }
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
    
    func isFavorite(_ word: Word) -> Bool {
        return favorites.contains(where: { $0.term == word.term })
    }
    
    func addToVocabulary(_ word: Word) {
        Task {
            do {
                try await APIService.shared.addToVocabulary(word)
                
                DispatchQueue.main.async {
                    if !self.vocabularyList.contains(where: { $0.term == word.term }) {
                        self.vocabularyList.append(word)
                    }
                }
            } catch {
                print("Error adding to vocabulary: \(error)")
            }
        }
    }
    
    func removeFromVocabulary(_ word: Word) {
        Task {
            do {
                try await APIService.shared.removeFromVocabulary(word)
                
                DispatchQueue.main.async {
                    self.vocabularyList.removeAll(where: { $0.term == word.term })
                }
            } catch {
                print("Error removing from vocabulary: \(error)")
            }
        }
    }
    
    func addToHistory(_ word: Word) {
        // This is automatically handled by the server when looking up words
        // Just update the local cache
        searchHistory.removeAll(where: { $0.term == word.term })
        searchHistory.insert(word, at: 0)
        
        if searchHistory.count > 100 {
            searchHistory = Array(searchHistory.prefix(100))
        }
    }
    
    func clearHistory() {
        Task {
            do {
                try await APIService.shared.clearSearchHistory()
                
                DispatchQueue.main.async {
                    self.searchHistory.removeAll()
                }
            } catch {
                print("Error clearing history: \(error)")
            }
        }
    }
    
    // Load data from API
    private func loadFavorites() async {
        do {
            let loadedFavorites = try await APIService.shared.getFavorites()
            
            DispatchQueue.main.async {
                self.favorites = loadedFavorites
            }
        } catch {
            print("Error loading favorites: \(error)")
        }
    }
    
    private func loadVocabulary() async {
        do {
            let loadedVocabulary = try await APIService.shared.getVocabulary()
            
            DispatchQueue.main.async {
                self.vocabularyList = loadedVocabulary
            }
        } catch {
            print("Error loading vocabulary: \(error)")
        }
    }
    
    private func loadHistory() async {
        do {
            let loadedHistory = try await APIService.shared.getSearchHistory()
            
            DispatchQueue.main.async {
                self.searchHistory = loadedHistory
            }
        } catch {
            print("Error loading history: \(error)")
        }
    }
    
    private func loadUnknownWords() async {
        do {
            let loadedUnknownWords = try await APIService.shared.getUnknownWords()
            
            DispatchQueue.main.async {
                self.unknownWords = loadedUnknownWords
            }
        } catch {
            print("Error loading unknown words: \(error)")
        }
    }
} 