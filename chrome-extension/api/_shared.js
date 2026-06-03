const STRIPE_API_BASE = 'https://api.stripe.com/v1'
const ACTIVE_SUBSCRIPTION_STATUSES = new Set(['active', 'trialing'])

export function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type')
}

export function handleOptions(req, res) {
  if (req.method === 'OPTIONS') {
    setCors(res)
    res.status(204).end()
    return true
  }
  return false
}

export function readJson(req) {
  return new Promise((resolve, reject) => {
    let body = ''
    req.on('data', (chunk) => {
      body += chunk
    })
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {})
      } catch (error) {
        reject(error)
      }
    })
  })
}

export function requireEnv(name) {
  const value = process.env[name]
  if (!value) {
    throw new Error(`Missing environment variable: ${name}`)
  }
  return value
}

export async function stripeRequest(path, init = {}) {
  const response = await fetch(`${STRIPE_API_BASE}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${requireEnv('STRIPE_SECRET_KEY')}`,
      ...init.headers,
    },
  })

  const data = await response.json()
  if (!response.ok) {
    throw new Error(data.error?.message || 'Stripe request failed')
  }
  return data
}

export async function getSubscriptionStatus(sessionId, installId) {
  const session = await stripeRequest(`/checkout/sessions/${encodeURIComponent(sessionId)}`)
  if (installId && session.metadata?.installId && session.metadata.installId !== installId) {
    return { pro: false, status: 'install_mismatch' }
  }

  if (!session.subscription) {
    return { pro: false, status: session.payment_status || 'missing_subscription' }
  }

  const subscription = await stripeRequest(
    `/subscriptions/${encodeURIComponent(session.subscription)}`,
  )
  return {
    pro: ACTIVE_SUBSCRIPTION_STATUSES.has(subscription.status),
    status: subscription.status,
    customerEmail: session.customer_details?.email || null,
  }
}

export function buildDefinitionPrompt(word, excludeWords, sections) {
  const optionalSections = [
    sections.simple ? '  <h3>更简单的说法</h3>\n  <p>用更口语、更基础的中文再解释一次。</p>' : '',
    sections.examples ? '  <h3>例句</h3>\n  <p><em>给一个短例句。</em></p>' : '',
    sections.collocations
      ? '  <h3>常见搭配</h3>\n  <ul><li>列出 1-3 个常见搭配，没有则写“暂无”。</li></ul>'
      : '',
  ].filter(Boolean)
  const excludePrompt = excludeWords?.length
    ? `\n注意：解释中请避免使用以下词语，用更简单的表达替代：${excludeWords.join('、')}`
    : ''

  return `请解释中文词语「${word}」的含义。请严格输出下面结构的纯 HTML 片段，不要输出 markdown，不要包含 \`\`\` 代码块：
<section>
  <h3>简明释义</h3>
  <p>用一句简洁易懂的话解释。</p>
${optionalSections.join('\n')}
</section>
要求：
1. 解释要准确、简洁
2. 尽量避免复杂词汇
3. 不要添加 CSS、script、style 或任何事件属性${excludePrompt}`
}
