# Testing Guide for AI Dictionary

This document outlines the testing procedures to verify that the AI Dictionary meets all the requirements specified in the feature.md file.

## Prerequisites

- Xcode 15.0 or later
- macOS 14.0 or later
- DeepSeek Chat API key (for production testing)

## Building and Running the App

1. Open `AIDictionary.xcodeproj` in Xcode
2. Set your development team for code signing
3. Build and run the application (⌘+R)

## Test Cases

### 1. AI Word Definition Generation

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Basic word lookup | 1. Enter a common word (e.g., "apple") in the search field<br>2. Click "Search" | Definition appears within 3 seconds |
| Complex word lookup | 1. Enter a more complex word (e.g., "photosynthesis")<br>2. Click "Search" | Definition appears and is clear and accurate |
| One-sentence definition | Check if the definitions are concise | Definition is a single sentence, not a paragraph |
| Native speaker quality | Review several definitions | Definitions match natural English phrasing |

### 2. Smart Vocabulary Filtering

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Marking unknown words | 1. Search for a word<br>2. Click on some words in the definition | Clicked words are highlighted and added to marked words list |
| Regeneration without marked words | 1. Mark several words in a definition<br>2. Click "Regenerate" | New definition appears without the marked words |
| Vocabulary management | 1. Add words to vocabulary<br>2. View in vocabulary list<br>3. Remove a word | Words appear in vocabulary list and can be removed |
| Vocabulary export | 1. Add some words to vocabulary<br>2. Click "Export Vocabulary"<br>3. Choose save location | File is created with all vocabulary words and definitions |

### 3. Text Selection and Floating Window

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| Global text selection | 1. Open any application (e.g., Safari)<br>2. Select a word<br>3. Press Command+D | Floating window appears with the definition |
| Window positioning | Check the floating window position | Window appears near the cursor position |
| Window dismissal | 1. Click outside the floating window | Window disappears |
| Response time | Measure time from Command+D to window appearance | Window appears in under 1 second |

### 4. System Performance

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| CPU usage | Monitor Activity Monitor during usage | CPU usage stays below 30% |
| Memory usage | Check memory usage in Activity Monitor | Memory usage stays below 200MB |
| Offline functionality | 1. Disconnect from internet<br>2. Look up previously searched words | Definitions for previously searched words are available |

### 5. UI Requirements

| Test Case | Steps | Expected Result |
|-----------|-------|-----------------|
| macOS design compliance | Visual inspection of UI elements | UI follows macOS design guidelines |
| Dark/light mode | 1. Switch system appearance<br>2. Check app appearance | App correctly adapts to system appearance |
| Window resizing | Try resizing the main window | Window content adapts to new size |
| Font size adjustment | 1. Go to Preferences<br>2. Adjust font size slider | Text size changes throughout the app |
| UI clarity | Evaluate overall UI organization | Important features are prominent and easy to access |
| Intuitive workflow | Test the main user flows | Operation feels natural and intuitive |

## Bug Reporting

When reporting bugs, please include:

1. Steps to reproduce the issue
2. Expected behavior
3. Actual behavior
4. Screenshots (if applicable)
5. System information (macOS version, etc.)

Report issues by creating a new issue in the project repository. 