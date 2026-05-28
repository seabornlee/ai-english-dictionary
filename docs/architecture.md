# AI English Dictionary - Architecture

## System Overview

```mermaid
flowchart TB
    subgraph Client["Client Applications"]
        MAC[macOS App<br/>SwiftUI]
        CHROME[Chrome Extension]
    end
    
    subgraph Server["Backend Server"]
        API[Express API<br/>Node.js]
        AUTH[Auth Middleware]
        LICENSE[License Middleware]
    end
    
    subgraph External["External Services"]
        DEEPSEEK[DeepSeek AI<br/>via SiliconFlow]
        MONGO[(MongoDB)]
        RESEND[Resend<br/>Email Service]
    end
    
    MAC --> |HTTPS| API
    CHROME --> |HTTPS| API
    API --> AUTH
    API --> LICENSE
    API --> DEEPSEEK
    API --> MONGO
    API --> RESEND
```

## Component Details

### macOS Application (mac-app/)

```mermaid
flowchart LR
    subgraph Views
        CV[ContentView]
        MBV[MenuBarView]
        PV[PreferencesView]
    end
    
    subgraph Services
        API[APIService]
        CM[ClipboardManager]
        NM[NetworkMonitor]
        WS[WordStore]
    end
    
    subgraph Models
        W[Word]
    end
    
    CV --> API
    MBV --> API
    CV --> WS
    MBV --> CM
    CV --> NM
    API --> W
```

**Key Components:**
- `ContentView`: Main dictionary interface
- `MenuBarView`: Menu bar popover UI
- `APIService`: HTTP client for backend communication
- `WordStore`: Local word storage and history
- `ClipboardManager`: System clipboard integration
- `NetworkMonitor`: Online/offline status tracking

### Backend Server (server/)

```mermaid
flowchart TB
    subgraph Routes
        DR[/api/dictionary]
        AR[/api/auth]
        SR[/api/sync]
    end
    
    subgraph Middleware
        LM[License Middleware]
        AM[Auth Middleware]
    end
    
    subgraph Controllers
        DC[DictionaryController]
    end
    
    subgraph Services
        AIS[AIService]
        ES[EmailService]
        RV[ReceiptValidator]
    end
    
    subgraph Models
        UW[UnknownWord]
        U[User]
        L[License]
    end
    
    DR --> LM --> DC
    AR --> AM
    SR --> LM
    DC --> AIS
    DC --> UW
    AIS --> |DeepSeek API| EXT[External AI]
```

**Key Components:**
- `AIService`: Interfaces with DeepSeek AI for word definitions
- `DictionaryController`: Handles word lookup, vocabulary, history
- `License Middleware`: Validates app licenses
- `Auth Middleware`: JWT-based user authentication

## Data Flow

### Word Definition Request

```mermaid
sequenceDiagram
    participant App as macOS App
    participant API as Express Server
    participant MW as License Middleware
    participant Ctrl as DictionaryController
    participant AI as AIService
    participant DB as MongoDB
    participant DeepSeek as DeepSeek AI

    App->>API: POST /api/dictionary/define
    API->>MW: Validate license token
    MW->>Ctrl: Forward request
    Ctrl->>DB: Get unknown words list
    DB-->>Ctrl: Unknown words
    Ctrl->>AI: getWordDefinition(word, unknownWords)
    AI->>DeepSeek: Chat completion request
    DeepSeek-->>AI: JSON definition
    AI-->>Ctrl: Normalized definition
    Ctrl->>DB: Save to history
    Ctrl-->>App: Word definition response
```

## Database Schema

### UnknownWord Collection
```javascript
{
  word: String,           // The word being defined
  unknownWords: [String], // Words user doesn't know
  createdAt: Date,
  updatedAt: Date
}
```

### User Collection
```javascript
{
  email: String,
  password: String,       // bcrypt hashed
  favorites: [{
    term: String,
    definition: String,
    pronunciation: String,
    partOfSpeech: String,
    exampleSentences: [String]
  }],
  vocabulary: [WordSchema],
  history: [WordSchema],
  isVerified: Boolean,
  verificationToken: String,
  createdAt: Date
}
```

### License Collection
```javascript
{
  licenseKey: String,
  email: String,
  deviceId: String,
  bundleId: String,
  isActive: Boolean,
  createdAt: Date,
  expiresAt: Date
}
```

## API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/dictionary/define` | POST | License | Get word definition from AI |
| `/api/dictionary/unknown-words` | GET | License | List all unknown words |
| `/api/dictionary/unknown-words` | POST | License | Add unknown word |
| `/api/dictionary/vocabulary` | GET | License | Get vocabulary list |
| `/api/auth/register` | POST | None | Register new user |
| `/api/auth/login` | POST | None | User login |
| `/api/auth/me` | GET | JWT | Get current user |
| `/api/sync/favorites` | GET/POST | JWT | Sync favorites |
| `/health` | GET | None | Health check |

## Deployment Architecture

```mermaid
flowchart TB
    subgraph GitHub
        GH[GitHub Repository]
        GA[GitHub Actions]
    end
    
    subgraph Production
        FLY[Fly.io<br/>Node.js Server]
        ATLAS[(MongoDB Atlas)]
    end
    
    subgraph Distribution
        DMG[DMG Download]
        BREW[Homebrew Tap]
    end
    
    GH --> GA
    GA --> |Deploy| FLY
    GA --> |Build & Notarize| DMG
    GA --> |Update| BREW
    FLY --> ATLAS
```

## Security Considerations

1. **License Validation**: All dictionary endpoints require valid license token
2. **JWT Authentication**: User endpoints use JWT with 30-day expiry
3. **Password Hashing**: bcrypt with salt rounds
4. **HTTPS Only**: All API communication over TLS
5. **Helmet.js**: Security headers on all responses
6. **CORS**: Configured for allowed origins
7. **Environment Variables**: Secrets stored in `.env` (never committed)
