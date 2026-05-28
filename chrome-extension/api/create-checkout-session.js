import { handleOptions, readJson, requireEnv, setCors, stripeRequest } from './_shared.js'

export default async function handler(req, res) {
  if (handleOptions(req, res)) return
  setCors(res)

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' })
    return
  }

  try {
    const { installId } = await readJson(req)
    const appUrl = requireEnv('APP_URL').replace(/\/+$/, '')
    const body = new URLSearchParams({
      mode: 'subscription',
      'line_items[0][price]': requireEnv('STRIPE_PRICE_ID'),
      'line_items[0][quantity]': '1',
      success_url: `${appUrl}/api/checkout-success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${appUrl}/api/checkout-cancelled`,
    })

    if (installId) {
      body.set('client_reference_id', installId)
      body.set('metadata[installId]', installId)
    }

    const session = await stripeRequest('/checkout/sessions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    })
    res.status(200).json({ url: session.url })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
}
