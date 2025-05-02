# AI English Dictionary

An AI-powered English-to-English dictionary that helps users learn and understand English words through pure English explanations.

## Features

- **AI-Generated Word Explanations**: Get detailed English explanations for words using DeepSeek Chat API
- **Smart Vocabulary Filtering**: Mark unknown words in explanations and regenerate simpler explanations
- **Global Text Selection**: Select text anywhere on your Mac and quickly look up definitions with Command+D

## Project Structure

The application is built with SwiftUI for macOS and includes:

- Core dictionary functionality with AI-powered definitions
- Global text selection with floating definition window
- Vocabulary management system with export capabilities
- Dark/light mode support and customizable preferences

## Setup

1. Open `AIDictionary.xcodeproj` in Xcode
2. Sign the app with your developer certificate
3. Obtain a DeepSeek Chat API key from [DeepSeek's website](https://deepseek.com)
4. In the app, go to Preferences > General and enter your API key
5. Build and run the application

## Usage

### Basic Usage

1. Type a word in the search box and click "Search" or press Command+Return
2. The definition will appear in the main view
3. Click on any word in the definition to mark it as unknown
4. Click "Regenerate" to get a new definition without the marked words

### Global Lookup

1. Select text in any application
2. Press Command+D
3. A floating window will appear with the definition
4. Click outside the window to dismiss it

### Vocabulary Management

1. Add words to your vocabulary by clicking the "+" button
2. Access your vocabulary list in the sidebar
3. Export your vocabulary as a text file for further study

## System Requirements

- macOS 14.0 or later
- Internet connection for API queries (local cache available for offline use)
- Accessibility permissions for global text selection

## Development Status

All features from the [feature.md](feature.md) document have been implemented and marked as complete.

## License

This project is licensed under the MIT License.
