import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var wordStore: WordStore
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var searchResult: Word?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Enter a word", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: performSearch) {
                    Text("Search")
                }
                .disabled(searchText.isEmpty || isLoading)
            }
            .padding([.horizontal, .top])
            
            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if let word = searchResult {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(word.term)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            wordStore.addToFavorites(word)
                        }) {
                            Image(systemName: wordStore.isFavorite(word) ? "star.fill" : "star")
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            wordStore.addToVocabulary(word)
                        }) {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Divider()
                    
                    Text(word.definition)
                        .lineLimit(5)
                }
                .padding()
                .frame(width: 300)
            } else {
                Text("Search for a word")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            Divider()
            
            HStack {
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showMainWindow:")), to: nil, from: nil)
                }) {
                    Text("Open Dictionary")
                }
                
                Spacer()
                
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Text("Quit")
                }
            }
            .padding()
        }
        .frame(width: 320)
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await APIService.shared.lookupWord(
                    searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                    unknownWords: []
                )
                
                DispatchQueue.main.async {
                    self.searchResult = result
                    self.isLoading = false
                    wordStore.addToHistory(result)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
} 