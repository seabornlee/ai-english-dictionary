/**
 * Structured logger for the Chrome extension.
 * Uses chrome.storage to persist recent log entries and provides
 * structured log levels (info, warn, error) with context objects.
 */

export type LogLevel = 'debug' | 'info' | 'warn' | 'error'

interface LogEntry {
  level: LogLevel
  message: string
  context?: Record<string, unknown>
  timestamp: string
  source: string
}

const MAX_LOG_ENTRIES = 200

const REDACT_KEYS = new Set([
  'apiKey',
  'api_key',
  'password',
  'token',
  'authorization',
  'secret',
  'creditCard',
  'ssn',
  'email',
])

function redact(context?: Record<string, unknown>): Record<string, unknown> | undefined {
  if (!context) return context
  const result: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(context)) {
    if (REDACT_KEYS.has(key)) {
      result[key] = '[REDACTED]'
    } else {
      result[key] = value
    }
  }
  return result
}

function createEntry(
  level: LogLevel,
  message: string,
  context?: Record<string, unknown>,
): LogEntry {
  return {
    level,
    message,
    context: redact(context),
    timestamp: new Date().toISOString(),
    source: 'chrome-ext',
  }
}

function formatEntry(entry: LogEntry): string {
  const ctx = entry.context ? ` ${JSON.stringify(entry.context)}` : ''
  return `[${entry.timestamp}] [${entry.level.toUpperCase()}] [${entry.source}] ${entry.message}${ctx}`
}

async function persistLog(entry: LogEntry): Promise<void> {
  try {
    const result = (await chrome.storage.local.get('logs')) as {
      logs?: LogEntry[]
    }
    const logs = result.logs ?? []
    logs.push(entry)
    const trimmed = logs.length > MAX_LOG_ENTRIES ? logs.slice(-MAX_LOG_ENTRIES) : logs
    await chrome.storage.local.set({ logs: trimmed })
  } catch {
    // Storage full or unavailable
  }
}

export const logger = {
  debug(message: string, context?: Record<string, unknown>): void {
    const entry = createEntry('debug', message, context)
    console.debug(formatEntry(entry))
  },

  info(message: string, context?: Record<string, unknown>): void {
    const entry = createEntry('info', message, context)
    console.info(formatEntry(entry))
    void persistLog(entry)
  },

  warn(message: string, context?: Record<string, unknown>): void {
    const entry = createEntry('warn', message, context)
    console.warn(formatEntry(entry))
    void persistLog(entry)
  },

  error(message: string, context?: Record<string, unknown>): void {
    const entry = createEntry('error', message, context)
    console.error(formatEntry(entry))
    void persistLog(entry)
  },

  async getRecentLogs(): Promise<LogEntry[]> {
    const result = (await chrome.storage.local.get('logs')) as {
      logs?: LogEntry[]
    }
    return result.logs ?? []
  },

  async clearLogs(): Promise<void> {
    await chrome.storage.local.remove('logs')
  },
}
