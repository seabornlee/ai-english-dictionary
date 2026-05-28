import { getConfig, getVocabulary, addWords, addWord } from '../lib/storage'
import { getDefinition } from '../lib/llm'
import { getAuthState, isAuthenticated } from '../lib/auth'
import { syncPushVocabulary } from '../lib/api-client'

// ── Message Handlers ──

chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  if (message.type === 'GET_DEFINITION') {
    handleGetDefinition(message.word)
      .then((definition) => sendResponse({ definition }))
      .catch((error) => sendResponse({ error: error.message }))
    return true
  }

  if (message.type === 'MARK_WORD') {
    addWord(message.word)
      .then(() => sendResponse({ success: true }))
      .catch((error) => sendResponse({ error: error.message }))
    return true
  }

  if (message.type === 'MARK_WORDS') {
    addWords(message.words)
      .then(() => sendResponse({ success: true }))
      .catch((error) => sendResponse({ error: error.message }))
    return true
  }

  if (message.type === 'SYNC_VOCABULARY') {
    syncVocabulary()
      .then(() => sendResponse({ success: true }))
      .catch((error) => sendResponse({ error: error.message }))
    return true
  }
})

async function handleGetDefinition(word: string): Promise<string> {
  const config = await getConfig()
  const vocabulary = await getVocabulary()
  const excludedWords = vocabulary.map((w) => w.word)
  return getDefinition(word, excludedWords, config)
}

// ── Vocabulary Sync ──

async function syncVocabulary(): Promise<void> {
  const authState = await getAuthState()
  if (!isAuthenticated(authState) || !authState.userToken) {
    return // Not logged in, nothing to sync
  }

  const vocabulary = await getVocabulary()
  if (vocabulary.length === 0) return

  try {
    await syncPushVocabulary(authState.serverUrl, authState.userToken, vocabulary)
  } catch (err) {
    console.error('Vocabulary sync failed:', err)
  }
}

// ── Alarm for Periodic Sync ──

chrome.runtime.onInstalled.addListener(() => {
  chrome.alarms.create('vocabulary-sync', { periodInMinutes: 30 })
})

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'vocabulary-sync') {
    syncVocabulary().catch(console.error)
  }
})