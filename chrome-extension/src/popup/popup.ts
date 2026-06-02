import { getLanguageInfo, type LanguageInfo } from '../lib/languages'
import { getConfig, getVocabulary, removeWord, type WordEntry } from '../lib/storage'

const wordList = document.getElementById('word-list') as HTMLUListElement
const emptyState = document.getElementById('empty-state') as HTMLElement
const settingsBtn = document.getElementById('settings-btn') as HTMLButtonElement
const exportBtn = document.getElementById('export-btn') as HTMLButtonElement
const clearBtn = document.getElementById('clear-btn') as HTMLButtonElement

let currentLang: LanguageInfo

async function init() {
  const config = await getConfig()
  currentLang = getLanguageInfo(config.language)
  applyLanguage()
  await loadWords()
}

function applyLanguage() {
  const p = currentLang.popup

  document.documentElement.lang = currentLang.code
  ;(document.getElementById('page-title') as HTMLElement).textContent = p.title
  ;(document.getElementById('main-title') as HTMLElement).textContent = p.title
  settingsBtn.title = p.settingsTooltip
  ;(document.getElementById('empty-text') as HTMLElement).textContent = p.emptyState
  ;(document.getElementById('empty-hint') as HTMLElement).textContent = p.emptyHint
  exportBtn.textContent = p.export
  clearBtn.textContent = p.clear
}

async function loadWords() {
  const vocabulary = await getVocabulary()
  renderWords(vocabulary)
}

function renderWords(words: WordEntry[]) {
  if (words.length === 0) {
    emptyState.classList.remove('hidden')
    wordList.classList.add('hidden')
    return
  }

  emptyState.classList.add('hidden')
  wordList.classList.remove('hidden')

  // Sort by date, newest first
  const sorted = [...words].sort((a, b) => b.addedAt - a.addedAt)

  wordList.innerHTML = sorted
    .map(
      (entry) => `
    <li class="word-item" data-word="${entry.word}">
      <div class="word-info">
        <span class="word-text">${entry.word}</span>
        <span class="word-date">${formatDate(entry.addedAt)}</span>
      </div>
      <button class="delete-btn" title="×">×</button>
    </li>
  `
    )
    .join('')

  // Add delete handlers
  wordList.querySelectorAll('.delete-btn').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      void deleteWord(e)
    })
  })
}

async function deleteWord(e: Event) {
  const li = (e.target as HTMLElement).closest('.word-item') as HTMLElement
  const word = li.dataset.word
  if (word) {
    await removeWord(word)
    await loadWords()
  }
}

function formatDate(timestamp: number): string {
  const date = new Date(timestamp)
  const now = new Date()
  const diff = now.getTime() - timestamp
  const p = currentLang.popup

  if (diff < 60000) return p.justNow
  if (diff < 3600000) return `${Math.floor(diff / 60000)}${p.minutesAgo}`
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}${p.hoursAgo}`
  if (date.toDateString() === now.toDateString()) return p.today

  return `${date.getMonth() + 1}/${date.getDate()}`
}

settingsBtn.addEventListener('click', () => {
  void chrome.runtime.openOptionsPage()
})

exportBtn.addEventListener('click', () => {
  void exportVocabulary()
})

async function exportVocabulary() {
  const vocabulary = await getVocabulary()
  const text = vocabulary.map((w) => w.word).join('\n')
  const blob = new Blob([text], { type: 'text/plain' })
  const url = URL.createObjectURL(blob)

  const a = document.createElement('a')
  a.href = url
  a.download = `vocabulary_${new Date().toISOString().slice(0, 10)}.txt`
  a.click()

  URL.revokeObjectURL(url)
}

clearBtn.addEventListener('click', () => {
  void clearVocabulary()
})

async function clearVocabulary() {
  if (confirm(currentLang.popup.clearConfirm)) {
    await chrome.storage.local.set({ vocabulary: [] })
    await loadWords()
  }
}

void init()
