import { LANGUAGE_OPTIONS, type ExplanationLanguage } from '../lib/languages'
import { getConfig, saveConfig } from '../lib/storage'

export async function ensureLanguageSelected(): Promise<ExplanationLanguage | null> {
  const config = await getConfig()
  if (config.language) {
    return config.language
  }

  showLanguageOnboarding(config)
  return null
}

export function isLanguageOnboardingTarget(target: EventTarget | null): boolean {
  return target instanceof HTMLElement && Boolean(target.closest('.lexis-language-onboarding'))
}

function showLanguageOnboarding(config: Awaited<ReturnType<typeof getConfig>>) {
  document.querySelector('.lexis-language-onboarding')?.remove()
  const overlay = document.createElement('div')
  overlay.className = 'lexis-language-onboarding'
  overlay.innerHTML = `
    <div class="lexis-language-card">
      <h2>选择界面语言</h2>
      <p>Choose interface language</p>
      <div class="lexis-language-options">
        ${renderLanguageButtons()}
      </div>
    </div>
  `

  overlay.querySelectorAll<HTMLButtonElement>('[data-language]').forEach((button) => {
    button.addEventListener('click', () => {
      const language = button.dataset.language as ExplanationLanguage
      void saveConfig({ ...config, language }).then(() => overlay.remove())
    })
  })

  document.body.appendChild(overlay)
}

function renderLanguageButtons(): string {
  return LANGUAGE_OPTIONS.map((item) => {
    return `<button data-language="${item.code}">${item.label}</button>`
  }).join('')
}
