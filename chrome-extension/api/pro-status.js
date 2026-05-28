import { getSubscriptionStatus, handleOptions, setCors } from './_shared.js'

export default async function handler(req, res) {
  if (handleOptions(req, res)) return
  setCors(res)

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' })
    return
  }

  try {
    const sessionId = req.query.session_id
    const installId = req.query.install_id
    if (!sessionId) {
      res.status(400).json({ error: 'Missing session_id' })
      return
    }

    const status = await getSubscriptionStatus(sessionId, installId)
    res.status(200).json(status)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
}
