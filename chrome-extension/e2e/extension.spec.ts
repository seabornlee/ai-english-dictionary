import {
  test,
  expect,
  chromium,
  type BrowserContext,
  type Page,
  type Worker,
} from '@playwright/test'
import { createServer, type IncomingMessage, type Server, type ServerResponse } from 'node:http'
import { mkdtemp } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import path from 'node:path'

const extensionPath = path.resolve('dist')

let apiServer: Server
let webServer: Server
let apiUrl: string
let webUrl: string
let prompts: string[] = []
let apiMode: 'normal' | 'empty' | 'empty-once' | 'malformed' = 'normal'

test.beforeAll(async () => {
  apiServer = await startServer(handleApiRequest)
  webServer = await startServer(handleWebRequest)
  apiUrl = getServerUrl(apiServer)
  webUrl = getServerUrl(webServer)
})

test.afterAll(async () => {
  await closeServer(apiServer)
  await closeServer(webServer)
})

test.beforeEach(() => {
  prompts = []
  apiMode = 'normal'
})

test('renders structured safe HTML explanation and supports multi-character word marking', async () => {
  test.setTimeout(60_000)
  const { context, extensionId } = await launchExtension()

  try {
    await configureApi(context, extensionId)

    const page = await context.newPage()
    await page.goto(webUrl)
    await selectText(page, '#target-word')

    const tooltip = page.locator('.lexis-tooltip')
    await expect(tooltip).toBeVisible()
    await expect(tooltip.locator('h3')).toHaveText(['简明释义'])
    expect(prompts[0]).toContain('Output format contract:')
    expect(prompts[0]).toContain('Return JSON only. Do not return HTML.')
    expect(prompts[0]).toContain('"basic": "one concise explanation"')
    expect(prompts[0]).toContain('简明释义')
    expect(prompts[0]).not.toContain('"simple"')
    expect(prompts[0]).not.toContain('"examples"')
    expect(prompts[0]).not.toContain('"collocations"')
    await expect(tooltip.locator('script')).toHaveCount(0)
    await expect(tooltip.locator('[onclick]')).toHaveCount(0)
    await expect(tooltip).not.toContainText('```')
    await expect
      .poll(() =>
        page.evaluate(() =>
          Boolean((window as Window & { __LEXIS_E2E_XSS?: boolean }).__LEXIS_E2E_XSS),
        ),
      )
      .toBe(false)

    const tooltipContent = tooltip.locator('.lexis-tooltip-content')
    await expect(tooltipContent).toHaveCSS('max-height', 'none')
    await expect(tooltipContent).toHaveCSS('overflow-y', 'visible')
    const firstMarkable = tooltip.locator('.lexis-markable').first()
    await expect(firstMarkable).toHaveCSS('font-size', '16px')
    await expect(firstMarkable).toHaveCSS('padding-left', '2px')
    // Discovery hint is shown on first use
    await expect(tooltip.locator('.lexis-discovery-hint')).toContainText('点击不认识的生词')
    await expect(firstMarkable).toHaveCSS('background-color', 'rgba(25, 118, 210, 0.06)')

    await fastDragFromTextToText(page, '复', '思')
    await expect(tooltip.locator('.lexis-selection-preview')).toHaveText(
      '点击生成不包含复杂意思的解释',
    )

    await fastDragFromTextToText(page, '复', '思')
    await expect(tooltip.locator('.lexis-tooltip-actions')).not.toHaveClass(/lexis-visible/)

    await dragAcrossText(page, '复杂')
    // Discovery hint is hidden when user selects text
    await expect(tooltip.locator('.lexis-discovery-hint')).toBeHidden()
    await expect(tooltip.locator('.lexis-selection-preview')).toHaveText('点击生成不包含复杂的解释')

    await dragAcrossText(page, '复杂')
    await expect(tooltip.locator('.lexis-tooltip-actions')).not.toHaveClass(/lexis-visible/)

    await dragAcrossText(page, '复杂')
    await dragAcrossText(page, '简单')
    await expect(tooltip.locator('.lexis-selection-preview')).toHaveText(
      '点击生成不包含复杂、简单的解释',
    )

    await page.evaluate(() => {
      document.querySelector<HTMLElement>('.lexis-confirm-btn')?.click()
    })
    await expect(tooltip).toContainText('重新解释后的简明释义')
    expect(prompts[prompts.length - 1]).toContain('复杂')
    expect(prompts[prompts.length - 1]).toContain('简单')

    // Discovery hint should NOT be shown after marking words
    await expect(tooltip.locator('.lexis-discovery-hint')).toHaveCount(0)

    const vocabulary = await getVocabulary(context)
    expect(vocabulary.map((entry) => entry.word)).toContain('复杂')
    expect(vocabulary.map((entry) => entry.word)).toContain('简单')
  } finally {
    await context.close()
  }
})

test('enables optional explanation sections from settings', async () => {
  const { context, extensionId } = await launchExtension()

  try {
    await configureApi(context, extensionId, {
      simple: true,
      examples: true,
      collocations: true,
    })

    const page = await context.newPage()
    await page.goto(webUrl)
    await selectText(page, '#target-word')

    const tooltip = page.locator('.lexis-tooltip')
    await expect(tooltip.locator('h3')).toHaveText(['简明释义', '更简单的说法', '例句', '常见搭配'])
    expect(prompts[0]).toContain('更简单的说法')
    expect(prompts[0]).toContain('例句')
    expect(prompts[0]).toContain('常见搭配')
  } finally {
    await context.close()
  }
})

test('guides first-time users to choose interface language', async () => {
  const { context, extensionId } = await launchExtension()

  try {
    await configureApi(context, extensionId, undefined, '')

    const page = await context.newPage()
    await page.goto(webUrl)
    await selectText(page, '#target-word')

    const onboarding = page.locator('.lexis-language-onboarding')
    await expect(onboarding).toBeVisible()
    await expect(onboarding).toContainText('Choose interface language')
    await onboarding.locator('[data-language="en"]').click()
    await expect(onboarding).toBeHidden()

    await selectText(page, '#target-word')

    const tooltip = page.locator('.lexis-tooltip')
    await expect(tooltip.locator('h3')).toHaveText(['简明释义'])
    await expect(tooltip.locator('.lexis-discovery-hint')).toContainText('Tip:')
    expect(prompts[0]).toContain('Output language: Simplified Chinese')
    expect(prompts[0]).toContain('basic: 简明释义')
  } finally {
    await context.close()
  }
})

test('uses selected text language for explanations regardless of interface language', async () => {
  const { context, extensionId } = await launchExtension()

  try {
    await configureApi(context, extensionId, undefined, 'zh-CN')

    const page = await context.newPage()
    await page.goto(webUrl)
    await selectText(page, '#english-target-word')

    const tooltip = page.locator('.lexis-tooltip')
    await expect(tooltip.locator('h3')).toHaveText(['Basic definition'])
    await expect(tooltip.locator('.lexis-discovery-hint')).toContainText('提示：')
    expect(prompts[0]).toContain('Output language: English')
    expect(prompts[0]).toContain('basic: Basic definition')
  } finally {
    await context.close()
  }
})

test('supports marking English words in explanation when querying English text', async () => {
  test.setTimeout(60_000)
  const { context, extensionId } = await launchExtension()

  try {
    await configureApi(context, extensionId, undefined, 'en')

    const page = await context.newPage()
    await page.goto(webUrl)
    await selectText(page, '#english-target-word')

    const tooltip = page.locator('.lexis-tooltip')
    await expect(tooltip).toBeVisible()
    await expect(tooltip.locator('h3')).toHaveText(['Basic definition'])

    // Verify English words are markable
    const markableWords = tooltip.locator('.lexis-markable')
    await expect(markableWords.first()).toBeVisible()

    // Get the first English word and click it
    const firstWord = await markableWords.first().textContent()
    expect(firstWord).toBeTruthy()
    expect(firstWord).toMatch(/^[a-zA-Z]+$/)

    // Click to select the word
    await markableWords.first().click()
    await expect(tooltip.locator('.lexis-selection-preview')).toContainText('Selected:')
    await expect(tooltip.locator('.lexis-selection-preview')).toContainText(firstWord!)

    // Confirm the selection
    await page.evaluate(() => {
      document.querySelector<HTMLElement>('.lexis-confirm-btn')?.click()
    })

    // Verify the word was saved to vocabulary
    const vocabulary = await getVocabulary(context)
    expect(vocabulary.map((entry) => entry.word)).toContain(firstWord)
  } finally {
    await context.close()
  }
})

test('shows an explicit error when the model returns empty content', async () => {
  apiMode = 'empty'
  const { context, extensionId } = await launchExtension()

  try {
    await configureApi(context, extensionId)

    const page = await context.newPage()
    await page.goto(webUrl)
    await selectText(page, '#target-word')

    const tooltip = page.locator('.lexis-tooltip')
    await expect(tooltip).toBeVisible()
    await expect(tooltip.locator('.lexis-tooltip-error')).toContainText('API 请求失败')
    await expect(tooltip.locator('.lexis-tooltip-error')).toContainText('empty response from model')
    await expect(tooltip.locator('.lexis-tooltip-text')).toHaveCount(0)
  } finally {
    await context.close()
  }
})

test('retries once when the first model response is empty', async () => {
  apiMode = 'empty-once'
  const { context, extensionId } = await launchExtension()

  try {
    await configureApi(context, extensionId)

    const page = await context.newPage()
    await page.goto(webUrl)
    await selectText(page, '#target-word')

    const tooltip = page.locator('.lexis-tooltip')
    await expect(tooltip).toBeVisible()
    await expect(tooltip.locator('h3')).toHaveText(['简明释义'])
    await expect(tooltip).toContainText('这是复杂意思')
    expect(prompts).toHaveLength(2)
  } finally {
    await context.close()
  }
})

async function launchExtension(): Promise<{ context: BrowserContext; extensionId: string }> {
  const userDataDir = await mkdtemp(path.join(tmpdir(), 'lexis-e2e-'))
  const context = await chromium.launchPersistentContext(userDataDir, {
    headless: false,
    args: [`--disable-extensions-except=${extensionPath}`, `--load-extension=${extensionPath}`],
  })
  let worker = context.serviceWorkers()[0]
  if (!worker) {
    worker = await context.waitForEvent('serviceworker')
  }
  const extensionId = worker.url().split('/')[2]
  return { context, extensionId }
}

async function configureApi(
  context: BrowserContext,
  extensionId: string,
  sections?: { simple?: boolean; examples?: boolean; collocations?: boolean },
  language = 'zh-CN',
) {
  const optionsPage = await context.newPage()
  await optionsPage.goto(`chrome-extension://${extensionId}/src/options/options.html`)
  await expect(optionsPage.locator('#pro-status')).toHaveCount(0)
  if (language) {
    await optionsPage.locator('#language').selectOption(language)
  }
  await optionsPage.locator('#provider').selectOption('custom')
  await optionsPage.locator('#apiKey').fill('test-api-key')
  await optionsPage.locator('#model').fill('test-model')
  await optionsPage.locator('#baseUrl').fill(`${apiUrl}/v1`)
  if (sections?.simple) {
    await optionsPage.locator('#section-simple').check()
  }
  if (sections?.examples) {
    await optionsPage.locator('#section-examples').check()
  }
  if (sections?.collocations) {
    await optionsPage.locator('#section-collocations').check()
  }
  await optionsPage.locator('button[type="submit"]').click()
  await expect(optionsPage.locator('#success-msg')).toBeVisible()
  await optionsPage.close()
}

async function selectText(page: Page, selector: string) {
  await page.locator(selector).evaluate((element) => {
    const range = document.createRange()
    range.selectNodeContents(element)
    const selection = window.getSelection()
    selection?.removeAllRanges()
    selection?.addRange(range)
    element.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }))
  })
}

async function dragAcrossText(page: Page, text: string) {
  await page.evaluate((targetText) => {
    const markables = Array.from(document.querySelectorAll<HTMLElement>('.lexis-markable'))

    // For CJK text, each character is a separate element
    // For Latin text, each word is a separate element
    const isCJK = /[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]/.test(targetText)

    if (isCJK) {
      // CJK: each character is separate
      const chars = Array.from(targetText)
      const startIndex = markables.findIndex((_, index) => {
        const candidate = markables.slice(index, index + chars.length)
        return candidate.map((el) => el.dataset.word).join('') === targetText
      })

      if (startIndex === -1) {
        throw new Error(`Markable text not found: ${targetText}`)
      }

      const elements = markables.slice(startIndex, startIndex + chars.length)
      elements[0].dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))
      elements.slice(1).forEach((el) => {
        el.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }))
      })
    } else {
      // Latin: find the word element directly
      const element = markables.find((el) => el.dataset.word === targetText)
      if (!element) {
        throw new Error(`Markable word not found: ${targetText}`)
      }
      element.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))
    }

    document.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }))
  }, text)
}

async function fastDragFromTextToText(page: Page, startText: string, endText: string) {
  await page.evaluate(
    ({ startText, endText }) => {
      const markables = Array.from(document.querySelectorAll<HTMLElement>('.lexis-markable'))

      const findElements = (text: string) => {
        const isCJK = /[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]/.test(text)

        if (isCJK) {
          const chars = Array.from(text)
          const startIndex = markables.findIndex((_, index) => {
            const candidate = markables.slice(index, index + chars.length)
            return candidate.map((el) => el.dataset.word).join('') === text
          })

          if (startIndex === -1) {
            throw new Error(`Markable text not found: ${text}`)
          }

          return markables.slice(startIndex, startIndex + chars.length)
        } else {
          const element = markables.find((el) => el.dataset.word === text)
          if (!element) {
            throw new Error(`Markable word not found: ${text}`)
          }
          return [element]
        }
      }

      const start = findElements(startText)[0]
      const end = findElements(endText).at(-1)

      start.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))
      end?.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }))
      document.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }))
    },
    { startText, endText },
  )
}

async function getVocabulary(context: BrowserContext): Promise<Array<{ word: string }>> {
  const worker = context.serviceWorkers()[0] || (await context.waitForEvent('serviceworker'))
  const result = await (worker as Worker).evaluate(() => chrome.storage.local.get('vocabulary'))
  return (result.vocabulary || []) as Array<{ word: string }>
}

function handleApiRequest(req: IncomingMessage, res: ServerResponse) {
  if (req.method !== 'POST' || req.url !== '/v1/chat/completions') {
    res.writeHead(404).end()
    return
  }

  let body = ''
  req.on('data', (chunk) => {
    body += chunk
  })
  req.on('end', () => {
    handleApiBody(body, res)
  })
}

function handleApiBody(body: string, res: ServerResponse) {
  const parsed = JSON.parse(body)
  const prompt = parsed.messages?.[0]?.content || ''
  prompts.push(prompt)

  if (apiMode === 'empty' || (apiMode === 'empty-once' && prompts.length === 1)) {
    sendChatCompletion(res, '')
    return
  }

  if (apiMode === 'malformed') {
    sendJson(res, { choices: [{ message: {} }] })
    return
  }

  sendChatCompletion(res, buildMockDefinition(prompt))
}

function buildMockDefinition(prompt: string): string {
  const usesEnglish = prompt.includes('Output language: English')
  const hasExcludedWord = prompt.includes('以下词语') && prompt.includes('复杂')
  const hasExcludedEnglishWord = prompt.includes('following words') || prompt.includes('exclude')
  const definition: Record<string, unknown> = {
    basic: getDefinitionText(usesEnglish, hasExcludedWord, hasExcludedEnglishWord),
  }

  if (prompt.includes('"simple"')) {
    definition.simple = '用简单话说明。'
  }
  if (prompt.includes('"examples"')) {
    definition.examples = ['词典帮助阅读。']
  }
  if (prompt.includes('"collocations"')) {
    definition.collocations = [{ phrase: '查词典', meaning: '' }]
  }

  return JSON.stringify(definition)
}

function getDefinitionText(
  usesEnglish: boolean,
  hasExcludedWord: boolean,
  hasExcludedEnglishWord: boolean,
): string {
  if (hasExcludedWord) return '重新解释后的简明释义。'
  if (hasExcludedEnglishWord) return 'Simplified explanation after marking words.'
  if (usesEnglish) return 'This is a clear explanation with simple words.'
  return '这是复杂意思，也可以简单说明。'
}

function sendChatCompletion(res: ServerResponse, content: string) {
  sendJson(res, { choices: [{ message: { content } }] })
}

function sendJson(res: ServerResponse, body: unknown) {
  res.writeHead(200, { 'content-type': 'application/json' })
  res.end(JSON.stringify(body))
}

function handleWebRequest(_req: IncomingMessage, res: ServerResponse) {
  res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' })
  res.end(`
    <!doctype html>
    <html lang="zh-CN">
      <body>
        <main>
          <p>这是一段测试文本：<span id="target-word">词典</span></p>
          <p>This is a test sentence: <span id="english-target-word">dictionary</span></p>
        </main>
      </body>
    </html>
  `)
}

function startServer(
  handler: (req: IncomingMessage, res: ServerResponse) => void,
): Promise<Server> {
  return new Promise((resolve) => {
    const server = createServer(handler)
    server.listen(0, '127.0.0.1', () => resolve(server))
  })
}

function closeServer(server: Server): Promise<void> {
  return new Promise((resolve, reject) => {
    server.closeAllConnections?.()
    server.close((error) => {
      if (error) reject(error)
      else resolve()
    })
  })
}

function getServerUrl(server: Server): string {
  const address = server.address()
  if (!address || typeof address === 'string') {
    throw new Error('Server did not start on a TCP port')
  }
  return `http://127.0.0.1:${address.port}`
}
