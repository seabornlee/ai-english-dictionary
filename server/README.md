# AI Dictionary Server

Backend server for the AI Dictionary Mac application.

## Features

- RESTful API for word definitions using DeepSeek Chat AI
- Endpoints for vocabulary management
- Favorites tracking
- Search history

## Setup

1. Install dependencies:

   ```
   npm install
   ```

2. Create a `.env` file in the root directory:

   ```
   cp src/config/example.env .env
   ```

3. Update the `.env` file with your DeepSeek API key

4. Start the development server:

   ```
   npm run dev
   ```

5. For production deployment:
   ```
   npm start
   ```

## API Endpoints

### Dictionary

- `POST /api/dictionary/define` - Define a word
- `POST /api/dictionary/vocabulary` - Add a word to vocabulary
- `GET /api/dictionary/vocabulary` - Get vocabulary list
- `DELETE /api/dictionary/vocabulary/:term` - Remove word from vocabulary
- `POST /api/dictionary/favorites` - Toggle favorite status
- `GET /api/dictionary/favorites` - Get favorites list
- `GET /api/dictionary/history` - Get search history
- `DELETE /api/dictionary/history` - Clear search history

## Development

The server uses in-memory storage by default. For production, you should implement a proper database solution.
