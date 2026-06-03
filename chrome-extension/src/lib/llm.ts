import { detectTextLanguage, getLanguageInfo } from './languages'
import { type ExplanationSections, type LLMConfig } from './storage'
import { defineWord, type DefineWordResponse } from './api-client'
import { getAuthState } from './auth'

export class LexisError extends Error {
  constructor(
    message: string,
    public readonly openSettings: boolean = false,
  ) {
    super(message)
    this.name = 'LexisError'
  }
}

type UnknownRecord = Record<string, unknown>
type ChatMessage = { role: 'user' | 'assistant'; content: string }

function isRecord(value: unknown): value is UnknownRecord {
  return typeof value === 'object' && value !== null
}

function extractTextContent(value: unknown): string {
  if (typeof value === 'string') {
    return value.trim()
  }

  if (Array.isArray(value)) {
    return value.map(extractTextContent).filter(Boolean).join('\n').trim()
  }

  if (isRecord(value)) {
    return extractTextContent(
      value.text ?? value.content ?? value.output_text ?? value.generated_text,
    )
  }

  return ''
}

function getResponseDetail(data: UnknownRecord): string {
  const choices = Array.isArray(data.choices) ? data.choices : []
  const firstChoice = choices[0]
  const firstChoiceRecord = isRecord(firstChoice) ? firstChoice : {}
  const finishReason = firstChoiceRecord.finish_reason
  const detail = typeof finishReason === 'string' ? ` (${finishReason})` : ''
  return detail
}

function emptyModelResponseError(config: LLMConfig, data?: UnknownRecord): LexisError {
  const errors = getLanguageInfo(config.language).errors
  return new LexisError(
    `${errors.apiRequestFailed}: empty response from model${data ? getResponseDetail(data) : ''}`,
  )
}

function invalidJsonResponseError(config: LLMConfig): LexisError {
  const errors = getLanguageInfo(config.language).errors
  return new LexisError(`${errors.apiRequestFailed}: invalid JSON response from model`)
}

export async function getDefinition(
  word: string,
  excludeWords: string[],
  config: LLMConfig,
): Promise<string> {
  if (config.provider === 'server') {
    const authState = await getAuthState()
    if (!authState.licenseToken) {
      const errors = getLanguageInfo(config.language).errors
      throw new LexisError(errors.licenseRequired, true)
    }
    const response = await defineWord(
      {
        baseUrl: authState.serverUrl,
        userToken: authState.userToken,
        licenseToken: authState.licenseToken,
      },
      {
        word,
        unknownWords: excludeWords,
        language: detectTextLanguage(word),
        explanationSections: config.explanationSections,
      },
    )
    return serverDefinitionToHtml(response, config.language)
  }

  if (!config.apiKey) {
    const errors = getLanguageInfo(config.language).errors
    throw new LexisError(errors.apiKeyRequired, true)
  }

  const outputLanguage = detectTextLanguage(word)
  const prompt = buildPrompt(word, excludeWords, config.explanationSections, outputLanguage)
  const messages: ChatMessage[] = [{ role: 'user', content: prompt }]

  const modelOutput =
    config.provider === 'claude'
      ? await callClaude(messages, config)
      : await callOpenAI(messages, config)

  return modelJsonToHtml(modelOutput, config, outputLanguage)
}

function buildPrompt(
  word: string,
  excludeWords: string[],
  sections: ExplanationSections,
  language: LLMConfig['language'],
): string {
  const languageInfo = getLanguageInfo(language)
  const headings = languageInfo.headings
  const excludePrompt =
    excludeWords.length > 0
      ? `\n注意：解释中请避免使用以下词语，用更简单的表达替代：${excludeWords.join('、')}`
      : ''

  const jsonFields = [
    '  "basic": "one concise explanation"',
    sections.simple ? '  "simple": "same meaning with simpler wording"' : '',
    sections.examples ? '  "examples": ["one short example sentence"]' : '',
    sections.collocations
      ? '  "collocations": [{"phrase": "common phrase", "meaning": "short meaning"}]'
      : '',
  ].filter(Boolean)

  const prompt = `请解释所选文本「${word}」的含义。
Output language: ${languageInfo.promptName}
Headings used by the app after parsing:
- basic: ${headings.basic}
- simple: ${headings.simple}
- examples: ${headings.examples}
- collocations: ${headings.collocations}
Output format contract:
- Return JSON only. Do not return HTML.
- Return exactly one JSON object, not an array.
- Do not output markdown, code fences, comments, or text outside JSON.
- All string values must be non-empty and written in Output language.
- Use this exact JSON shape and omit fields that are not listed:
{
${jsonFields.join(',\n')}
}
- If the meaning is uncertain, still fill "basic" and explain the uncertainty there.
要求：
1. 解释要准确、简洁
2. 所有标题和解释内容都必须使用 Output language
3. 绝不能返回空内容${excludePrompt}`
  return prompt
}

async function callOpenAI(messages: ChatMessage[], config: LLMConfig): Promise<string> {
  let lastData: UnknownRecord | undefined
  const retryMessages: ChatMessage[] = [
    ...messages,
    {
      role: 'user',
      content: 'The previous response was empty. Return the requested JSON object now.',
    },
  ]

  for (const currentMessages of [messages, retryMessages]) {
    const data = await requestOpenAI(currentMessages, config)
    lastData = data
    const content = extractOpenAIContent(data)

    if (content) {
      return content
    }
  }

  throw emptyModelResponseError(config, lastData)
}

async function requestOpenAI(messages: ChatMessage[], config: LLMConfig): Promise<UnknownRecord> {
  const response = await fetch(`${config.baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${config.apiKey}`,
    },
    body: JSON.stringify({
      model: config.model,
      messages,
      max_tokens: 500,
      temperature: 0.2,
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    const errors = getLanguageInfo(config.language).errors
    throw new LexisError(`${errors.apiRequestFailed}: ${error}`)
  }

  return (await response.json()) as UnknownRecord
}

function extractOpenAIContent(data: UnknownRecord): string {
  const choices = Array.isArray(data.choices) ? data.choices : []
  const firstChoice = choices[0]
  const firstChoiceRecord = isRecord(firstChoice) ? firstChoice : {}
  const message = isRecord(firstChoiceRecord.message) ? firstChoiceRecord.message : {}
  const candidates = [
    message.content,
    message.text,
    firstChoiceRecord.text,
    firstChoiceRecord.content,
    data.output_text,
    data.output,
    data.response,
    data.result,
    data.generated_text,
    data.text,
    data.content,
  ]

  return extractTextContent(candidates)
}

async function callClaude(messages: ChatMessage[], config: LLMConfig): Promise<string> {
  const response = await fetch(`${config.baseUrl}/messages`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': config.apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: config.model,
      max_tokens: 500,
      messages,
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    const errors = getLanguageInfo(config.language).errors
    throw new LexisError(`${errors.apiRequestFailed}: ${error}`)
  }

  const data = (await response.json()) as UnknownRecord
  const content = extractTextContent(data.content)

  if (!content) {
    throw emptyModelResponseError(config, data)
  }

  return content
}

function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

function modelJsonToHtml(
  raw: string,
  config: LLMConfig,
  outputLanguage: LLMConfig['language'],
): string {
  const trimmed = raw.trim()
  if (trimmed.startsWith('<')) {
    return trimmed
  }

  const parsed = parseJsonObject(trimmed, config)
  const basic = getStringField(parsed, 'basic')

  if (!basic) {
    throw invalidJsonResponseError(config)
  }

  const headings = getLanguageInfo(outputLanguage).headings
  const sections: string[] = [
    '<section>',
    `<h3>${headings.basic}</h3>`,
    `<p>${escapeHtml(basic)}</p>`,
  ]

  appendOptionalJsonSections(sections, parsed, config, outputLanguage)
  sections.push('</section>')
  return sections.join('\n')
}

function parseJsonObject(raw: string, config: LLMConfig): UnknownRecord {
  const jsonText = stripJsonFence(raw)

  try {
    const parsed = JSON.parse(jsonText) as unknown
    if (isRecord(parsed)) {
      return parsed
    }
  } catch {
    const firstBrace = jsonText.indexOf('{')
    const lastBrace = jsonText.lastIndexOf('}')
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      return parseJsonObject(jsonText.slice(firstBrace, lastBrace + 1), config)
    }
  }

  throw invalidJsonResponseError(config)
}

function stripJsonFence(raw: string): string {
  const fenceMatch = raw.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i)
  return fenceMatch ? fenceMatch[1].trim() : raw
}

function getStringField(record: UnknownRecord, field: string): string {
  const value = record[field]
  return typeof value === 'string' ? value.trim() : ''
}

function appendOptionalJsonSections(
  html: string[],
  parsed: UnknownRecord,
  config: LLMConfig,
  outputLanguage: LLMConfig['language'],
) {
  const headings = getLanguageInfo(outputLanguage).headings

  if (config.explanationSections.simple) {
    const simple = getStringField(parsed, 'simple')
    if (simple) {
      html.push(`<h3>${headings.simple}</h3>`, `<p>${escapeHtml(simple)}</p>`)
    }
  }

  if (config.explanationSections.examples) {
    appendStringListSection(html, headings.examples, parsed.examples, true)
  }

  if (config.explanationSections.collocations) {
    appendCollocationSection(html, headings.collocations, parsed.collocations)
  }
}

function appendStringListSection(html: string[], heading: string, value: unknown, italic = false) {
  if (!Array.isArray(value)) return

  const items = value.map((item) => (typeof item === 'string' ? item.trim() : '')).filter(Boolean)
  if (items.length === 0) return

  const listItems = items
    .slice(0, 3)
    .map((item) => `<li>${italic ? `<em>${escapeHtml(item)}</em>` : escapeHtml(item)}</li>`)
    .join('')
  html.push(`<h3>${heading}</h3>`, `<ul>${listItems}</ul>`)
}

function appendCollocationSection(html: string[], heading: string, value: unknown) {
  if (!Array.isArray(value)) return

  const listItems = value.map(collocationToHtml).filter(Boolean).slice(0, 3).join('')
  if (listItems) {
    html.push(`<h3>${heading}</h3>`, `<ul>${listItems}</ul>`)
  }
}

function collocationToHtml(value: unknown): string {
  if (typeof value === 'string') {
    return value.trim() ? `<li>${escapeHtml(value.trim())}</li>` : ''
  }

  if (!isRecord(value)) return ''

  const phrase = getStringField(value, 'phrase')
  const meaning = getStringField(value, 'meaning')
  if (!phrase) return ''

  return `<li><strong>${escapeHtml(phrase)}</strong>${meaning ? `: ${escapeHtml(meaning)}` : ''}</li>`
}

export function serverDefinitionToHtml(
  response: DefineWordResponse,
  language: LLMConfig['language'],
): string {
  const headings = getLanguageInfo(language).headings
  const sections: string[] = ['<section>']

  // Basic definition
  sections.push(`<h3>${headings.basic}</h3>`)
  sections.push(`<p>${escapeHtml(response.definition)}</p>`)

  // Simpler wording
  if (response.simpleDefinition) {
    sections.push(`<h3>${headings.simple}</h3>`)
    sections.push(`<p>${escapeHtml(response.simpleDefinition)}</p>`)
  }

  // Example sentences
  const examples = response.examples ?? response.exampleSentences
  if (examples && examples.length > 0) {
    sections.push(`<h3>${headings.examples}</h3>`)
    const listItems = examples
      .slice(0, 3)
      .map((s) => `<li><em>${escapeHtml(s)}</em></li>`)
      .join('')
    sections.push(`<ul>${listItems}</ul>`)
  }

  // Collocations
  if (response.collocations && response.collocations.length > 0) {
    sections.push(`<h3>${headings.collocations}</h3>`)
    const listItems = response.collocations
      .slice(0, 3)
      .map(
        (c) =>
          `<li><strong>${escapeHtml(c.phrase)}</strong>${c.meaning ? `: ${escapeHtml(c.meaning)}` : ''}</li>`,
      )
      .join('')
    sections.push(`<ul>${listItems}</ul>`)
  }

  sections.push('</section>')
  return sections.join('\n')
}
