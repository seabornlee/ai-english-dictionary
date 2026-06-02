import { type ExplanationLanguage, getLanguageInfo } from '../lib/languages'
import { getConfig, saveConfig, type LLMConfig } from '../lib/storage'

// ── DOM Elements ──

const form = document.getElementById('config-form') as HTMLFormElement
const languageSelect = document.getElementById('language') as HTMLSelectElement
const providerSelect = document.getElementById('provider') as HTMLSelectElement
const apiKeyInput = document.getElementById('apiKey') as HTMLInputElement
const modelInput = document.getElementById('model') as HTMLInputElement
const baseUrlInput = document.getElementById('baseUrl') as HTMLInputElement
const simpleSectionInput = document.getElementById('section-simple') as HTMLInputElement
const examplesSectionInput = document.getElementById('section-examples') as HTMLInputElement
const collocationsSectionInput = document.getElementById('section-collocations') as HTMLInputElement
const successMsg = document.getElementById('success-msg') as HTMLElement

const apiKeyGroup = document.getElementById('api-key-group') as HTMLElement
const modelGroup = document.getElementById('model-group') as HTMLElement
const baseUrlGroup = document.getElementById('base-url-group') as HTMLElement

// ── Provider Defaults ──

const defaultModels: Record<string, string> = {
  openai: 'gpt-4o-mini',
  claude: 'claude-3-haiku-20240307',
  custom: 'gpt-4o-mini',
}

const defaultUrls: Record<string, string> = {
  openai: 'https://api.openai.com/v1',
  claude: 'https://api.anthropic.com/v1',
  custom: '',
}

// ── i18n ──

function applyLanguage(lang: ExplanationLanguage) {
  const info = getLanguageInfo(lang)
  const s = info.settings

  document.documentElement.lang = lang || 'en'
  ;(document.getElementById('page-title') as HTMLElement).textContent = s.title
  ;(document.getElementById('main-title') as HTMLElement).textContent = s.title
  ;(document.getElementById('label-language') as HTMLElement).textContent = s.interfaceLanguage
  ;(document.getElementById('hint-language') as HTMLElement).textContent = s.interfaceLanguageHint
  ;(document.getElementById('option-select-first') as HTMLElement).textContent = s.selectOnFirstUse
  ;(document.getElementById('label-provider') as HTMLElement).textContent = s.provider
  ;(document.getElementById('option-custom') as HTMLElement).textContent = s.customOpenAI
  ;(document.getElementById('label-apiKey') as HTMLElement).textContent = s.apiKey
  ;(document.getElementById('hint-apiKey') as HTMLElement).textContent = s.apiKeyHint
  ;(document.getElementById('label-model') as HTMLElement).textContent = s.modelName
  ;(document.getElementById('hint-model') as HTMLElement).textContent = s.modelHint
  ;(document.getElementById('label-baseUrl') as HTMLElement).textContent = s.baseUrl
  ;(document.getElementById('hint-baseUrl') as HTMLElement).textContent = s.baseUrlHint
  ;(document.getElementById('legend-content') as HTMLElement).textContent = s.explanationContent
  ;(document.getElementById('hint-content') as HTMLElement).textContent = s.explanationContentHint
  ;(document.getElementById('label-simple') as HTMLElement).textContent = s.simplerWording
  ;(document.getElementById('label-examples') as HTMLElement).textContent = s.examples
  ;(document.getElementById('label-collocations') as HTMLElement).textContent = s.collocations
  ;(document.getElementById('btn-save') as HTMLElement).textContent = s.saveSettings
  successMsg.textContent = s.settingsSaved
}

// ── Toggle API fields visibility ──

function toggleApiFields() {
  apiKeyGroup.style.display = ''
  modelGroup.style.display = ''
  baseUrlGroup.style.display = ''
}

// ── Config Form ──

languageSelect.addEventListener('change', () => {
  const lang = languageSelect.value as ExplanationLanguage
  applyLanguage(lang)
})

providerSelect.addEventListener('change', () => {
  const provider = providerSelect.value
  modelInput.placeholder = defaultModels[provider] || ''
  baseUrlInput.placeholder = defaultUrls[provider] || ''
  toggleApiFields()
})

form.addEventListener('submit', (e) => {
  e.preventDefault()
  void saveFormConfig()
})

async function saveFormConfig() {
  const config: LLMConfig = {
    provider: providerSelect.value as LLMConfig['provider'],
    apiKey: apiKeyInput.value,
    model: modelInput.value || defaultModels[providerSelect.value],
    baseUrl: baseUrlInput.value || defaultUrls[providerSelect.value],
    language: languageSelect.value as ExplanationLanguage,
    explanationSections: {
      simple: simpleSectionInput.checked,
      examples: examplesSectionInput.checked,
      collocations: collocationsSectionInput.checked,
    },
  }

  await saveConfig(config)
  successMsg.classList.add('show')
  setTimeout(() => {
    successMsg.classList.remove('show')
  }, 2000)
}

async function loadConfig() {
  const config = await getConfig()
  languageSelect.value = config.language
  providerSelect.value = config.provider
  apiKeyInput.value = config.apiKey
  modelInput.value = config.model
  baseUrlInput.value = config.baseUrl
  simpleSectionInput.checked = config.explanationSections.simple
  examplesSectionInput.checked = config.explanationSections.examples
  collocationsSectionInput.checked = config.explanationSections.collocations
  toggleApiFields()
  applyLanguage(config.language)
}

// ── Init ──

void loadConfig()
