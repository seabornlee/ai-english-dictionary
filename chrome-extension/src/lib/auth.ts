const DEFAULT_SERVER_URL = 'https://ai-dictionary-server.fly.dev'

export interface AuthState {
  userToken: string | null
  licenseToken: string | null
  email: string | null
  serverUrl: string
}

function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const payload = token.split('.')[1]
    return JSON.parse(atob(payload))
  } catch {
    return null
  }
}

function isTokenExpired(token: string): boolean {
  const payload = decodeJwtPayload(token)
  if (!payload || !payload.exp) return true
  return Date.now() > (payload.exp as number) * 1000
}

const DEFAULT_AUTH_STATE: AuthState = {
  userToken: null,
  licenseToken: null,
  email: null,
  serverUrl: DEFAULT_SERVER_URL,
}

export async function getAuthState(): Promise<AuthState> {
  const result = (await chrome.storage.sync.get('authState')) as {
    authState?: Partial<AuthState>
  }
  return { ...DEFAULT_AUTH_STATE, ...result.authState }
}

export async function setAuthState(state: Partial<AuthState>): Promise<void> {
  const current = await getAuthState()
  await chrome.storage.sync.set({ authState: { ...current, ...state } })
}

export async function clearAuthState(): Promise<void> {
  await chrome.storage.sync.set({ authState: DEFAULT_AUTH_STATE })
}

export function isAuthenticated(state: AuthState): boolean {
  return !!state.userToken && !isTokenExpired(state.userToken)
}

export function isLicensed(state: AuthState): boolean {
  return !!state.licenseToken && !isTokenExpired(state.licenseToken)
}

export async function ensureDeviceId(): Promise<string> {
  const result = (await chrome.storage.local.get('deviceId')) as { deviceId?: string }
  if (result.deviceId) return result.deviceId

  const deviceId = `chrome-${crypto.randomUUID()}`
  await chrome.storage.local.set({ deviceId })
  return deviceId
}
