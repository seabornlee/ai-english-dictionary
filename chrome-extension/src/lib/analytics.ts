/**
 * Lightweight event tracking for the Chrome extension.
 * Stores events in chrome.storage.local for local analytics.
 */

export interface AnalyticsEvent {
  name: string
  properties?: Record<string, unknown>
  timestamp: string
}

const MAX_EVENTS = 500
const STORAGE_KEY = 'analytics_events'

export const analytics = {
  async track(name: string, properties?: Record<string, unknown>): Promise<void> {
    const event: AnalyticsEvent = {
      name,
      properties,
      timestamp: new Date().toISOString(),
    }

    try {
      const result = (await chrome.storage.local.get(STORAGE_KEY)) as {
        analytics_events?: AnalyticsEvent[]
      }
      const events = result.analytics_events ?? []
      events.push(event)
      const trimmed = events.length > MAX_EVENTS ? events.slice(-MAX_EVENTS) : events
      await chrome.storage.local.set({ [STORAGE_KEY]: trimmed })
    } catch {
      // Storage full or unavailable
    }
  },

  async getEvents(): Promise<AnalyticsEvent[]> {
    const result = (await chrome.storage.local.get(STORAGE_KEY)) as {
      analytics_events?: AnalyticsEvent[]
    }
    return result.analytics_events ?? []
  },

  async clearEvents(): Promise<void> {
    await chrome.storage.local.remove(STORAGE_KEY)
  },
}
