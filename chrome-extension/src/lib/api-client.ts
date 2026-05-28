import type { ExplanationLanguage } from './languages'
import type { ExplanationSections } from './storage'

export interface ServerAuth {
  baseUrl: string
  userToken: string | null
  licenseToken: string | null
}

export interface DefineWordParams {
  word: string
  unknownWords?: string[]
  language?: ExplanationLanguage
  explanationSections?: ExplanationSections
}

export interface Collocation {
  phrase: string
  meaning: string
}

export interface DefineWordResponse {
  term: string
  definition: string
  pronunciation: string | null
  partOfSpeech: string | null
  exampleSentences: string[]
  simpleDefinition: string | null
  examples: string[] | null
  collocations: Collocation[] | null
  language: string
  timestamp: string
}

async function apiRequest<T>(
  baseUrl: string,
  path: string,
  options: {
    method?: string
    token?: string | null
    body?: unknown
  } = {}
): Promise<T> {
  const { method = 'GET', token, body } = options

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: response.statusText }))
    throw new Error(error.error || `API request failed: ${response.status}`)
  }

  return response.json() as Promise<T>
}

// ── Dictionary API (requires license JWT) ──

export async function defineWord(
  auth: ServerAuth,
  params: DefineWordParams
): Promise<DefineWordResponse> {
  return apiRequest<DefineWordResponse>(auth.baseUrl, '/api/dictionary/define', {
    method: 'POST',
    token: auth.licenseToken,
    body: {
      word: params.word,
      unknownWords: params.unknownWords ?? [],
      language: params.language ?? 'en',
      explanationSections: params.explanationSections ?? {},
    },
  })
}

// ── Auth API ──

export interface AuthResponse {
  token: string
  user: {
    email: string
    isVerified: boolean
  }
  message?: string
}

export async function register(
  baseUrl: string,
  email: string,
  password: string
): Promise<AuthResponse> {
  return apiRequest<AuthResponse>(baseUrl, '/api/auth/register', {
    method: 'POST',
    body: { email, password },
  })
}

export async function login(
  baseUrl: string,
  email: string,
  password: string
): Promise<AuthResponse> {
  return apiRequest<AuthResponse>(baseUrl, '/api/auth/login', {
    method: 'POST',
    body: { email, password },
  })
}

export interface ActivateResponse {
  success: boolean
  token: string
  licenseId: string
  message: string
}

export async function activateLicense(
  baseUrl: string,
  userToken: string,
  deviceId: string
): Promise<ActivateResponse> {
  return apiRequest<ActivateResponse>(baseUrl, '/api/auth/activate-chrome', {
    method: 'POST',
    token: userToken,
    body: { deviceId },
  })
}

export interface LicenseStatusResponse {
  valid: boolean
  licenseId: string
  bundleId: string
  [key: string]: unknown
}

export async function getLicenseStatus(
  baseUrl: string,
  licenseToken: string
): Promise<LicenseStatusResponse> {
  return apiRequest<LicenseStatusResponse>(baseUrl, '/api/auth/license-status', {
    token: licenseToken,
  })
}

// ── Sync API (requires user JWT) ──

export interface SyncVocabularyEntry {
  word: string
  addedAt: number
  context?: string
}

export async function syncPushVocabulary(
  baseUrl: string,
  userToken: string,
  vocabulary: SyncVocabularyEntry[]
): Promise<{ success: boolean; count: number }> {
  return apiRequest<{ success: boolean; count: number }>(
    baseUrl,
    '/api/sync/chrome/vocabulary',
    {
      method: 'PUT',
      token: userToken,
      body: { vocabulary },
    }
  )
}

export async function syncPullVocabulary(
  baseUrl: string,
  userToken: string
): Promise<{ vocabulary: SyncVocabularyEntry[] }> {
  return apiRequest<{ vocabulary: SyncVocabularyEntry[] }>(
    baseUrl,
    '/api/sync/chrome/vocabulary',
    { token: userToken }
  )
}