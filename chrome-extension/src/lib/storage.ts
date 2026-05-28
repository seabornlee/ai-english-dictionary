import { type ExplanationLanguage } from './languages'

export interface LLMConfig {
  provider: 'openai' | 'claude' | 'custom' | 'server'
  apiKey: string
  model: string
  baseUrl: string
  language: ExplanationLanguage
  explanationSections: ExplanationSections
}

export interface ExplanationSections {
  simple: boolean
  examples: boolean
  collocations: boolean
}

export interface WordEntry {
  word: string
  addedAt: number
  context?: string
}

const DEFAULT_CONFIG: LLMConfig = {
  provider: 'openai',
  apiKey: '',
  model: 'gpt-4o-mini',
  baseUrl: 'https://api.openai.com/v1',
  language: '',
  explanationSections: {
    simple: false,
    examples: false,
    collocations: false,
  },
}

export async function getConfig(): Promise<LLMConfig> {
  const result = (await chrome.storage.sync.get('llmConfig')) as { llmConfig?: Partial<LLMConfig> }
  const config = result.llmConfig ?? {}
  return {
    ...DEFAULT_CONFIG,
    ...config,
    explanationSections: {
      ...DEFAULT_CONFIG.explanationSections,
      ...config.explanationSections,
    },
  }
}

export async function saveConfig(config: LLMConfig): Promise<void> {
  await chrome.storage.sync.set({ llmConfig: config })
}

export async function getVocabulary(): Promise<WordEntry[]> {
  const result = (await chrome.storage.local.get('vocabulary')) as { vocabulary?: WordEntry[] }
  return result.vocabulary ?? []
}

export async function addWord(word: string, context?: string): Promise<void> {
  await addWords([word], context)
}

export async function addWords(words: string[], context?: string): Promise<void> {
  const vocabulary = await getVocabulary()
  const existingWords = new Set(vocabulary.map((entry) => entry.word))
  const addedAt = Date.now()
  let changed = false

  words.forEach((word) => {
    const normalizedWord = word.trim()
    if (normalizedWord && !existingWords.has(normalizedWord)) {
      vocabulary.push({ word: normalizedWord, addedAt, context })
      existingWords.add(normalizedWord)
      changed = true
    }
  })

  if (changed) {
    await chrome.storage.local.set({ vocabulary })
  }
}

export async function removeWord(word: string): Promise<void> {
  const vocabulary = await getVocabulary()
  const filtered = vocabulary.filter((w) => w.word !== word)
  await chrome.storage.local.set({ vocabulary: filtered })
}

export async function getExcludedWords(): Promise<string[]> {
  const vocabulary = await getVocabulary()
  return vocabulary.map((w) => w.word)
}
