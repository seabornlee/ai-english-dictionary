# AI English Dictionary (LexisDic)

An AI-powered English-to-English dictionary that helps users learn and understand English words through pure English explanations. Available on the Mac App Store with auto-renewable subscription.

## Features

- **AI-Generated Word Explanations**: Get detailed English explanations for words using DeepSeek Chat API
- **Smart Vocabulary Filtering**: Mark unknown words in explanations and regenerate simpler explanations
- **Menu Bar Quick Access**: Click the menu bar icon for instant word lookup
- **Services Menu Integration**: Select text in any app → right-click → Services → "Look up in LexisDic"
- **Share Extension**: Share selected text from any app to LexisDic for instant lookup

## Project Structure

The application is built with SwiftUI for macOS and includes:

- Core dictionary functionality with AI-powered definitions
- Menu bar popup for quick word lookup (sandbox-compatible)
- Vocabulary management system with export capabilities
- Dark/light mode support and customizable preferences
- App Sandbox compliance for Mac App Store distribution

## Setup

1. Open `AIDictionary.xcodeproj` in Xcode
2. Sign the app with your developer certificate (Team ID: `6RT3UH94M6`)
3. Build and run the application

## Usage

### Basic Usage

1. Click the menu bar icon (book icon) to open the dictionary popup
2. Type a word in the search field and press Return
3. The definition will appear in the results area
4. Click on any word in the definition to mark it as unknown
5. Click "Regenerate" to get a new definition without the marked words

### Services Menu

1. Select text in any application
2. Right-click → Services → "Look up in LexisDic"
3. The definition appears in the LexisDic popup

### Vocabulary Management

1. Add words to your vocabulary by clicking the "+" button
2. Access your vocabulary list in the sidebar
3. Export your vocabulary as a text file for further study

## System Requirements

- macOS 13.0 or later
- Internet connection for API queries (local cache available for offline use)

## Development Status

All features from the [feature.md](feature.md) document have been implemented and marked as complete.

## License

This project is licensed under the MIT License.
