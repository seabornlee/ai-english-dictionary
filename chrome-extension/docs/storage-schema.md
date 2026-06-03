# Chrome Extension Storage Schema

This document describes the data structures stored in `chrome.storage` by the Lexis Chrome extension.

## chrome.storage.sync

### `llmConfig` — LLM Configuration

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `provider` | `'openai' \| 'claude' \| 'custom' \| 'server'` | `'openai'` | API provider |
| `apiKey` | `string` | `''` | API key for the provider |
| `model` | `string` | `'gpt-4o-mini'` | Model name |
| `baseUrl` | `string` | `'https://api.openai.com/v1'` | API base URL |
| `language` | `ExplanationLanguage` | `''` | Explanation language code |
| `explanationSections` | `ExplanationSections` | `{simple:false, examples:false, collocations:false}` | Toggle explanation sections |

### `authState` — Authentication State

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `userToken` | `string \| null` | `null` | Backend JWT for authenticated requests |
| `licenseToken` | `string \| null` | `null` | License JWT for dictionary API |
| `email` | `string \| null` | `null` | User email |
| `serverUrl` | `string` | `'https://ai-dictionary-server.fly.dev'` | Backend server URL |

## chrome.storage.local

### `vocabulary` — Word List

Array of `WordEntry` objects:

| Field | Type | Description |
|-------|------|-------------|
| `word` | `string` | The vocabulary word (normalized, trimmed) |
| `addedAt` | `number` | Unix timestamp (ms) when added |
| `context` | `string \| undefined` | Optional context where word was found |

### `deviceId` — Device Identifier

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `deviceId` | `string` | Auto-generated | Unique device ID (`chrome-{uuid}`) |

### `hasMarkedWord` — Onboarding Flag

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `hasMarkedWord` | `boolean` | `false` | Whether user has used the word-marking feature |

## TypeScript Interfaces

Source: `src/lib/storage.ts`, `src/lib/auth.ts`

```typescript
interface LLMConfig { provider, apiKey, model, baseUrl, language, explanationSections }
interface ExplanationSections { simple, examples, collocations }
interface WordEntry { word, addedAt, context? }
interface AuthState { userToken, licenseToken, email, serverUrl }
```
