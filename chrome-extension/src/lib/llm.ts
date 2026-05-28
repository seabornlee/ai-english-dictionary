import { detectTextLanguage, getLanguageInfo } from './languages'
import { type ExplanationSections, type LLMConfig } from './storage'
import { defineWord, type DefineWordResponse } from './api-client'
import { getAuthState } from './auth'

export async function getDefinition(
  word: string,
  excludeWords: string[],
  config: LLMConfig
): Promise<string> {
  if (config.provider === 'server') {
    const authState = await getAuthState()
    if (!authState.licenseToken) {
      throw new Error('请先在设置中登录并激活许可证')
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
      }
    )
    return serverDefinitionToHtml(response, config.language)
  }

  if (!config.apiKey) {
    throw new Error('请先在设置中配置 API Key')
  }

  const prompt = buildPrompt(
    word,
    excludeWords,
    config.explanationSections,
    detectTextLanguage(word)
  )
  const messages = [{ role: 'user' as const, content: prompt }]

  if (config.provider === 'claude') {
    return callClaude(messages, config)
  } else {
    return callOpenAI(messages, config)
  }
}

function buildPrompt(
  word: string,
  excludeWords: string[],
  sections: ExplanationSections,
  language: LLMConfig['language']
): string {
  const languageInfo = getLanguageInfo(language)
  const headings = languageInfo.headings
  const excludePrompt =
    excludeWords.length > 0
      ? `\n注意：解释中请避免使用以下词语，用更简单的表达替代：${excludeWords.join('、')}`
      : ''

  const optionalSections = [
    sections.simple
      ? `  <h3>${headings.simple}</h3>\n  <p>Use simpler and more basic wording.</p>`
      : '',
    sections.examples ? `  <h3>${headings.examples}</h3>\n  <p><em>Give one short example.</em></p>` : '',
    sections.collocations
      ? `  <h3>${headings.collocations}</h3>\n  <ul><li>List 1-3 common collocations, or say none.</li></ul>`
      : '',
  ].filter(Boolean)

  const sectionTemplate = [
    '<section>',
    `  <h3>${headings.basic}</h3>`,
    '  <p>Explain in one concise, easy-to-understand sentence.</p>',
    ...optionalSections,
    '</section>',
  ].join('\n')

  const prompt = `请解释所选文本「${word}」的含义。
Output language: ${languageInfo.promptName}
请严格输出下面结构的纯 HTML 片段，不要输出 markdown，不要包含 \`\`\` 代码块：
${sectionTemplate}
要求：
1. 解释要准确、简洁
2. 所有标题和解释内容都必须使用 Output language
3. 不要添加 CSS、script、style 或任何事件属性${excludePrompt}`
  return prompt
}

async function callOpenAI(
  messages: { role: 'user' | 'assistant'; content: string }[],
  config: LLMConfig
): Promise<string> {
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
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`API 请求失败: ${error}`)
  }

  const data = await response.json()
  return data.choices[0].message.content
}

async function callClaude(
  messages: { role: 'user' | 'assistant'; content: string }[],
  config: LLMConfig
): Promise<string> {
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
    throw new Error(`API 请求失败: ${error}`)
  }

  const data = await response.json()
  return data.content[0].text
}

function escapeHtml(text: string): string {
  const div = document.createElement('div')
  div.appendChild(document.createTextNode(text))
  return div.innerHTML
}

export function serverDefinitionToHtml(
  response: DefineWordResponse,
  language: LLMConfig['language']
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
          `<li><strong>${escapeHtml(c.phrase)}</strong>${c.meaning ? `: ${escapeHtml(c.meaning)}` : ''}</li>`
      )
      .join('')
    sections.push(`<ul>${listItems}</ul>`)
  }

  sections.push('</section>')
  return sections.join('\n')
}
