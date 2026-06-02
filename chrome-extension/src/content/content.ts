import { getLanguageInfo, isSupportedSelection, type ExplanationLanguage } from '../lib/languages'
import { hasMarkedWordBefore, setHasMarkedWord } from '../lib/storage'
import { LexisError } from '../lib/llm'
import { ensureLanguageSelected, isLanguageOnboardingTarget, setPendingSelection } from './language-onboarding'

interface TooltipState {
  element: HTMLElement | null
  currentWord: string
  language: ExplanationLanguage
  selectedIndices: Set<number>
  dragMode: 'select' | 'deselect' | null
  dragAnchorIndex: number | null
  dragVisitedIndices: Set<number>
}

const state: TooltipState = {
  element: null,
  currentWord: '',
  language: 'zh-CN',
  selectedIndices: new Set(),
  dragMode: null,
  dragAnchorIndex: null,
  dragVisitedIndices: new Set(),
}

function createTooltip(): HTMLElement {
  const texts = getLanguageInfo(state.language).ui
  const tooltip = document.createElement('div')
  tooltip.className = 'lexis-tooltip'
  tooltip.innerHTML = `
    <div class="lexis-tooltip-header">
      <span class="lexis-tooltip-word"></span>
      <div class="lexis-tooltip-header-actions">
        <button class="lexis-tooltip-settings" title="Settings">⚙️</button>
        <button class="lexis-tooltip-close">×</button>
      </div>
    </div>
    <div class="lexis-tooltip-content">
      <div class="lexis-tooltip-loading">${texts.loading}</div>
    </div>
    <div class="lexis-tooltip-footer">
      <span class="lexis-tooltip-hint">${texts.footerHint}</span>
    </div>
  `
  document.body.appendChild(tooltip)

  tooltip.querySelector('.lexis-tooltip-close')?.addEventListener('click', hideTooltip)
  tooltip.querySelector('.lexis-tooltip-settings')?.addEventListener('click', () => {
    void chrome.runtime.sendMessage({ type: 'OPEN_OPTIONS' })
  })

  return tooltip
}

export function showTooltip(word: string, x: number, y: number, language: ExplanationLanguage) {
  state.language = language
  // Force recreate tooltip to ensure it's always up-to-date
  if (state.element) {
    state.element.remove()
    state.element = null
  }
  state.element = createTooltip()

  state.currentWord = word
  const tooltip = state.element
  const texts = getLanguageInfo(state.language).ui

  const wordEl = tooltip.querySelector('.lexis-tooltip-word')
  if (wordEl) wordEl.textContent = word

  const contentEl = tooltip.querySelector('.lexis-tooltip-content')
  if (contentEl) {
    contentEl.innerHTML = `<div class="lexis-tooltip-loading">${texts.loading}</div>`
  }

  tooltip.style.display = 'block'
  tooltip.style.left = `${x}px`
  tooltip.style.top = `${y}px`

  // Adjust position if tooltip goes off screen
  const rect = tooltip.getBoundingClientRect()
  if (rect.right > window.innerWidth) {
    tooltip.style.left = `${window.innerWidth - rect.width - 10}px`
  }
  if (rect.bottom > window.innerHeight) {
    tooltip.style.top = `${y - rect.height - 10}px`
  }

  // Request definition from background
  chrome.runtime.sendMessage({ type: 'GET_DEFINITION', word }, (response) => {
    handleDefinitionResponse(response)
  })
}

function handleDefinitionResponse(response?: {
  definition?: string
  error?: string
  openSettings?: boolean
}) {
  const errors = getLanguageInfo(state.language).errors

  if (chrome.runtime.lastError) {
    showError(`${errors.apiRequestFailed}: ${chrome.runtime.lastError.message}`)
    return
  }

  if (!response) {
    showError(`${errors.apiRequestFailed}: no response from extension`)
    return
  }

  if (response.error) {
    showError(response.error, response.openSettings)
    return
  }

  if (!response.definition?.trim()) {
    showError(`${errors.apiRequestFailed}: empty response from model`)
    return
  }

  void showDefinition(response.definition)
}

function hideTooltip() {
  if (state.element) {
    state.element.style.display = 'none'
  }
  state.currentWord = ''
}

function updateTooltipLanguageText() {
  const texts = getLanguageInfo(state.language).ui
  const hintEl = state.element?.querySelector('.lexis-tooltip-hint')
  if (hintEl) {
    hintEl.textContent = texts.footerHint
  }
}

function showError(message: string, openSettings = false) {
  const contentEl = state.element?.querySelector('.lexis-tooltip-content')
  if (contentEl) {
    const settingsLabel = getLanguageInfo(state.language).settings.title
    const settingsBtn = openSettings
      ? `<button class="lexis-error-settings-btn">${settingsLabel}</button>`
      : ''
    contentEl.innerHTML = `<div class="lexis-tooltip-error">${message}${settingsBtn}</div>`

    if (openSettings) {
      const btn = contentEl.querySelector('.lexis-error-settings-btn')
      btn?.addEventListener('click', () => {
        void chrome.runtime.sendMessage({ type: 'OPEN_OPTIONS' })
      })
    }
  }
}

async function showDefinition(definition: string) {
  const contentEl = state.element?.querySelector('.lexis-tooltip-content')
  if (!contentEl) return

  state.selectedIndices.clear()
  state.dragMode = null
  state.dragAnchorIndex = null
  state.dragVisitedIndices.clear()

  const texts = getLanguageInfo(state.language).ui
  updateTooltipLanguageText()

  // Only show discovery hint if user hasn't marked a word before
  const showHint = !(await hasMarkedWordBefore())

  const sanitized = sanitizeDefinitionHtml(definition)
  const processedText = makeWordsClickable(sanitized)

  if (!processedText || !processedText.trim()) {
    const errors = getLanguageInfo(state.language).errors
    showError(`${errors.apiRequestFailed}: empty response from model`)
    return
  }

  contentEl.innerHTML = `
    ${showHint ? `<div class="lexis-discovery-hint">${texts.discoveryHint}</div>` : ''}
    <div class="lexis-tooltip-text">${processedText}</div>
    <div class="lexis-tooltip-actions">
      <span class="lexis-selection-preview"></span>
      <button class="lexis-confirm-btn">${texts.confirmButton}</button>
    </div>
  `

  contentEl.querySelectorAll('.lexis-markable').forEach((el) => {
    el.addEventListener('mousedown', (e) => {
      e.preventDefault()
      const target = e.target as HTMLElement
      const index = Number(target.dataset.index)
      if (!Number.isNaN(index)) {
        startDragSelection(target, index)
      }
    })
    el.addEventListener('mouseenter', (e) => {
      const target = e.target as HTMLElement
      const index = Number(target.dataset.index)
      if (!Number.isNaN(index)) {
        applyDragSelection(target, index)
      }
    })
  })

  const confirmBtn = contentEl.querySelector('.lexis-confirm-btn')
  confirmBtn?.addEventListener('click', () => {
    if (state.selectedIndices.size > 0) {
      markSelectedAndRefresh()
    }
  })
}

function startDragSelection(el: HTMLElement, index: number) {
  state.dragMode = state.selectedIndices.has(index) ? 'deselect' : 'select'
  state.dragAnchorIndex = index
  state.dragVisitedIndices.clear()
  applyDragSelection(el, index)
}

function applyDragSelection(_el: HTMLElement, index: number) {
  if (!state.dragMode || state.dragAnchorIndex === null) return

  const start = Math.min(state.dragAnchorIndex, index)
  const end = Math.max(state.dragAnchorIndex, index)

  for (let currentIndex = start; currentIndex <= end; currentIndex += 1) {
    if (state.dragVisitedIndices.has(currentIndex)) continue

    const el = state.element?.querySelector<HTMLElement>(
      `.lexis-markable[data-index="${currentIndex}"]`
    )
    if (el) {
      state.dragVisitedIndices.add(currentIndex)
      setCharSelection(el, currentIndex, state.dragMode === 'select')
    }
  }
}

function endDragSelection() {
  state.dragMode = null
  state.dragAnchorIndex = null
  state.dragVisitedIndices.clear()
}

function setCharSelection(el: HTMLElement, index: number, selected: boolean) {
  if (selected) {
    state.selectedIndices.add(index)
    el.classList.add('lexis-selected')
  } else {
    state.selectedIndices.delete(index)
    el.classList.remove('lexis-selected')
  }

  updateSelectionPreview()
}

function updateSelectionPreview() {
  const hintEl = state.element?.querySelector<HTMLElement>('.lexis-discovery-hint')
  const actionsEl = state.element?.querySelector<HTMLElement>('.lexis-tooltip-actions')
  const previewEl = state.element?.querySelector<HTMLElement>('.lexis-selection-preview')
  const selectedTerms = getSelectedTerms()
  if (hintEl && selectedTerms.length > 0) {
    hintEl.hidden = true
  }
  if (actionsEl) {
    actionsEl.classList.toggle('lexis-visible', selectedTerms.length > 0)
  }
  if (previewEl) {
    const texts = getLanguageInfo(state.language).ui
    previewEl.textContent =
      selectedTerms.length > 0
        ? `${texts.selectedPrefix}${selectedTerms.join('、')}${texts.selectedSuffix}`
        : ''
  }
}

function markSelectedAndRefresh() {
  const words = getSelectedTerms()
  if (words.length === 0) return
  
  const contentEl = state.element?.querySelector('.lexis-tooltip-content')
  if (contentEl) {
    const texts = getLanguageInfo(state.language).ui
    contentEl.innerHTML = `<div class="lexis-tooltip-loading">${texts.markingPrefix}${words.join('、')}${texts.markingSuffix}</div>`
  }

  void saveSelectedWords(words).then(async () => {
    // Mark that user has used this feature, so we won't show the hint again
    await setHasMarkedWord()
    
    chrome.runtime.sendMessage(
      { type: 'GET_DEFINITION', word: state.currentWord },
      (response) => {
        handleDefinitionResponse(response)
      }
    )
  }).catch((error: Error) => {
    showError(error.message, error instanceof LexisError ? error.openSettings : false)
  })
}

function saveSelectedWords(words: string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    chrome.runtime.sendMessage({ type: 'MARK_WORDS', words }, (response) => {
      if (chrome.runtime.lastError) {
        reject(new Error(chrome.runtime.lastError.message))
        return
      }
      if (response?.error) {
        reject(new Error(response.error))
        return
      }
      resolve()
    })
  })
}

function getSelectedTerms(): string[] {
  const selectedEls = Array.from(
    state.element?.querySelectorAll<HTMLElement>('.lexis-markable.lexis-selected') || []
  )

  const sorted = selectedEls
    .map((el) => ({
      index: Number(el.dataset.index),
      word: el.dataset.word || '',
    }))
    .filter((item) => !Number.isNaN(item.index) && item.word)
    .sort((a, b) => a.index - b.index)

  // CJK characters (single char) should be merged when consecutive
  // Latin words (multi-char) should remain separate
  const isSingleChar = (word: string) => word.length === 1 && /[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]/.test(word)
  
  const terms: string[] = []
  let current = ''
  let previousIndex = -2

  sorted.forEach(({ index, word }) => {
    if (isSingleChar(word) && index === previousIndex + 1 && isSingleChar(current.slice(-1))) {
      // Consecutive CJK single characters - merge them
      current += word
    } else {
      // Either not consecutive, or it's a Latin word - treat as separate term
      if (current) terms.push(current)
      current = word
    }
    previousIndex = index
  })

  if (current) terms.push(current)
  return terms
}

function sanitizeDefinitionHtml(html: string): string {
  const container = document.createElement('div')
  container.innerHTML = html
  const allowedTags = new Set(['SECTION', 'H3', 'P', 'OL', 'UL', 'LI', 'EM', 'STRONG', 'B', 'BR'])

  function clean(node: Node) {
    if (node.nodeType === Node.COMMENT_NODE) {
      node.parentNode?.removeChild(node)
      return
    }

    if (node.nodeType !== Node.ELEMENT_NODE) {
      return
    }

    const element = node as HTMLElement
    Array.from(element.childNodes).forEach(clean)

    if (!allowedTags.has(element.tagName)) {
      element.replaceWith(...Array.from(element.childNodes))
      return
    }

    Array.from(element.attributes).forEach((attr) => element.removeAttribute(attr.name))
  }

  Array.from(container.childNodes).forEach(clean)
  return container.innerHTML
}

function makeWordsClickable(html: string): string {
  const container = document.createElement('div')
  container.innerHTML = html
  let charIndex = 0

  const combinedRegex = /([\u4e00-\u9fff]|[\u3040-\u30ff]|[\uac00-\ud7af]|[a-zA-ZÀ-ÿ]+(?:[-'][a-zA-ZÀ-ÿ]+)*)/g

  function processNode(node: Node) {
    if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent || ''
      if (combinedRegex.test(text)) {
        combinedRegex.lastIndex = 0 // Reset regex state
        const span = document.createElement('span')
        span.innerHTML = text.replace(combinedRegex, (match) => {
          const escaped = match.replace(/"/g, '&quot;')
          return `<span class="lexis-markable" data-word="${escaped}" data-index="${charIndex++}">${match}</span>`
        })
        node.parentNode?.replaceChild(span, node)
      }
    } else if (node.nodeType === Node.ELEMENT_NODE) {
      Array.from(node.childNodes).forEach(processNode)
    }
  }

  processNode(container)
  return container.innerHTML
}



function getSelectedText(): string {
  const selection = window.getSelection()
  if (!selection) return ''
  return selection.toString().trim()
}

function handleScroll(e: Event) {
  if (state.element?.contains(e.target as Node)) {
    return
  }

  hideTooltip()
}

async function handleMouseUp(e: MouseEvent) {
  if (isLanguageOnboardingTarget(e.target)) {
    return
  }

  if (state.dragMode) {
    endDragSelection()
    return
  }

  // Ignore clicks inside tooltip
  if (state.element?.contains(e.target as Node)) return

  const selectedText = getSelectedText()

  if (selectedText && selectedText.length <= 40 && isSupportedSelection(selectedText)) {
    await showTooltipForSelectedText(selectedText)
  } else if (!state.element?.contains(e.target as Node)) {
    hideTooltip()
  }
}

async function showTooltipForSelectedText(selectedText: string) {
  // Save selection text for when language onboarding completes
  setPendingSelection(selectedText)
  const language = await ensureLanguageSelected()
  const selection = window.getSelection()
  if (!language || !selection || selection.rangeCount === 0) return

  const range = selection.getRangeAt(0)
  const rect = range.getBoundingClientRect()
  showTooltip(selectedText, rect.left + window.scrollX, rect.bottom + window.scrollY + 5, language)
}

// Listen for text selection
document.addEventListener('mouseup', (e) => {
  void handleMouseUp(e)
})

// Hide tooltip when the page scrolls, but keep it open while scrolling inside the tooltip.
document.addEventListener('scroll', handleScroll, true)

// Hide tooltip on escape key
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    hideTooltip()
  }
})

// Handle language selection after onboarding
document.addEventListener('lexis-language-selected', ((e: Event) => {
  console.log('[Lexis] Received lexis-language-selected event')
  const customEvent = e as CustomEvent<{ text: string; language: ExplanationLanguage }>
  const { text, language } = customEvent.detail
  console.log('[Lexis] Event detail:', { text, language })
  const selection = window.getSelection()
  console.log('[Lexis] Selection:', selection, 'rangeCount:', selection?.rangeCount)
  if (selection && selection.rangeCount > 0) {
    const range = selection.getRangeAt(0)
    const rect = range.getBoundingClientRect()
    console.log('[Lexis] Showing tooltip with rect:', rect)
    showTooltip(text, rect.left + window.scrollX, rect.bottom + window.scrollY + 5, language)
  } else {
    console.log('[Lexis] No selection, cannot show tooltip!')
  }
}) as EventListener)
