import { describe, it, expect, beforeEach } from 'vitest'
import {
  getAuthState,
  setAuthState,
  clearAuthState,
  isAuthenticated,
  isLicensed,
  ensureDeviceId,
} from './auth'
import type { AuthState } from './auth'

const DEFAULT_SERVER_URL = 'https://ai-dictionary-server.fly.dev'

// Mock chrome.storage API
const storageMock = {
  sync: {
    data: {} as Record<string, unknown>,
    get(keys: string | string[]) {
      const keyList = Array.isArray(keys) ? keys : [keys]
      const result: Record<string, unknown> = {}
      for (const key of keyList) {
        if (key in this.data) {
          result[key] = this.data[key]
        }
      }
      return Promise.resolve(result)
    },
    set(items: Record<string, unknown>) {
      Object.assign(this.data, items)
      return Promise.resolve()
    },
  },
  local: {
    data: {} as Record<string, unknown>,
    get(keys: string | string[]) {
      const keyList = Array.isArray(keys) ? keys : [keys]
      const result: Record<string, unknown> = {}
      for (const key of keyList) {
        if (key in this.data) {
          result[key] = this.data[key]
        }
      }
      return Promise.resolve(result)
    },
    set(items: Record<string, unknown>) {
      Object.assign(this.data, items)
      return Promise.resolve()
    },
  },
}

// @ts-expect-error - mocking global chrome API
globalThis.chrome = { storage: storageMock }

function makeFutureJwt(expSeconds: number): string {
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
  const payload = btoa(JSON.stringify({ exp: expSeconds }))
  const signature = btoa('fake-signature')
  return `${header}.${payload}.${signature}`
}

const FUTURE_EXP = Math.floor(Date.now() / 1000) + 3600
const PAST_EXP = Math.floor(Date.now() / 1000) - 3600

describe('auth module', () => {
  beforeEach(() => {
    storageMock.sync.data = {}
    storageMock.local.data = {}
  })

  describe('isAuthenticated', () => {
    it('returns true when userToken is valid and not expired', () => {
      const state: AuthState = {
        userToken: makeFutureJwt(FUTURE_EXP),
        licenseToken: null,
        email: 'test@example.com',
        serverUrl: DEFAULT_SERVER_URL,
      }
      expect(isAuthenticated(state)).toBe(true)
    })

    it('returns false when userToken is null', () => {
      const state: AuthState = {
        userToken: null,
        licenseToken: null,
        email: null,
        serverUrl: DEFAULT_SERVER_URL,
      }
      expect(isAuthenticated(state)).toBe(false)
    })

    it('returns false when userToken is expired', () => {
      const state: AuthState = {
        userToken: makeFutureJwt(PAST_EXP),
        licenseToken: null,
        email: null,
        serverUrl: DEFAULT_SERVER_URL,
      }
      expect(isAuthenticated(state)).toBe(false)
    })
  })

  describe('isLicensed', () => {
    it('returns true when licenseToken is valid and not expired', () => {
      const state: AuthState = {
        userToken: null,
        licenseToken: makeFutureJwt(FUTURE_EXP),
        email: null,
        serverUrl: DEFAULT_SERVER_URL,
      }
      expect(isLicensed(state)).toBe(true)
    })

    it('returns false when licenseToken is null', () => {
      const state: AuthState = {
        userToken: null,
        licenseToken: null,
        email: null,
        serverUrl: DEFAULT_SERVER_URL,
      }
      expect(isLicensed(state)).toBe(false)
    })
  })

  describe('getAuthState', () => {
    it('returns default state when nothing is stored', async () => {
      const state = await getAuthState()
      expect(state.userToken).toBeNull()
      expect(state.licenseToken).toBeNull()
      expect(state.email).toBeNull()
      expect(state.serverUrl).toBe(DEFAULT_SERVER_URL)
    })
  })

  describe('setAuthState', () => {
    it('merges partial state with existing state', async () => {
      await setAuthState({ email: 'user@test.com' })
      const state = await getAuthState()
      expect(state.email).toBe('user@test.com')
    })
  })

  describe('clearAuthState', () => {
    it('resets state to defaults', async () => {
      await setAuthState({ email: 'user@test.com', userToken: makeFutureJwt(FUTURE_EXP) })
      await clearAuthState()
      const state = await getAuthState()
      expect(state.email).toBeNull()
      expect(state.userToken).toBeNull()
    })
  })

  describe('ensureDeviceId', () => {
    it('creates a new deviceId when none exists', async () => {
      const id = await ensureDeviceId()
      expect(id).toMatch(/^chrome-/)
    })

    it('returns existing deviceId when one is stored', async () => {
      const first = await ensureDeviceId()
      const second = await ensureDeviceId()
      expect(first).toBe(second)
    })
  })
})
