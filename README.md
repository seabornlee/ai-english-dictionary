# AI English Dictionary

An AI-powered English-to-English dictionary application for macOS that helps users learn and understand English words without relying on translations.

## Project Structure

This project consists of two main components:

1. **ai-dic-mac**: A native macOS application built with SwiftUI that provides:
   - Global word lookup with keyboard shortcuts
   - Word definitions using AI
   - Vocabulary management
   - Favorites and history tracking

2. **ai-dic-server**: A Node.js backend server that:
   - Interacts with DeepSeek Chat API for word definitions
   - Provides storage for user data (favorites, vocabulary, history)
   - Handles avoiding words in definitions when requested

## Setup Instructions

### Backend Server

1. Navigate to the server directory:
   ```
   cd ai-dic-server
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Create a `.env` file:
   ```
   cp src/config/example.env .env
   ```

4. Add your DeepSeek API key to the `.env` file

5. Start the development server:
   ```
   npm run dev
   ```

### macOS Application

1. Open the Xcode project:
   ```
   open ai-dic-mac/AIDictionary.xcodeproj
   ```

2. Update the server URL in `APIService.swift` if needed

3. Build and run the application in Xcode

## Features

- **AI-powered definitions**: Get concise English explanations for words
- **Smart vocabulary filtering**: Mark and avoid unknown words in definitions
- **Global word lookup**: Access the dictionary from any application with keyboard shortcuts
- **Favorites and vocabulary management**: Keep track of important words
- **Search history**: Review previously looked up words

## Technical Implementation

- macOS app built with SwiftUI and Swift
- Node.js backend with Express
- RESTful API for communication between client and server
- Integration with DeepSeek Chat AI for word definitions 