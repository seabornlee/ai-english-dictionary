import {
  buildDefinitionPrompt,
  getSubscriptionStatus,
  handleOptions,
  readJson,
  requireEnv,
  setCors,
} from './_shared.js'

export default async function handler(req, res) {
  if (handleOptions(req, res)) return
  setCors(res)

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' })
    return
  }

  try {
    const { sessionId, installId, word, excludeWords = [], sections = {} } = await readJson(req)
    if (!sessionId || !word) {
      res.status(400).json({ error: 'Missing sessionId or word' })
      return
    }

    const status = await getSubscriptionStatus(sessionId, installId)
    if (!status.pro) {
      res.status(402).json({ error: 'Pro subscription is not active', status: status.status })
      return
    }

    const definition = await callOpenAI(buildDefinitionPrompt(word, excludeWords, sections))
    res.status(200).json({ definition })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
}

async function callOpenAI(prompt) {
  const response = await fetch(`${getOpenAIBaseUrl()}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${requireEnv('OPENAI_API_KEY')}`,
    },
    body: JSON.stringify({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 500,
    }),
  })

  const data = await response.json()
  if (!response.ok) {
    throw new Error(data.error?.message || 'OpenAI request failed')
  }
  return data.choices[0].message.content
}

function getOpenAIBaseUrl() {
  return (process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1').replace(/\/+$/, '')
}
