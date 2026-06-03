export default function handler(req, res) {
  res.status(200).json({ status: 'ok', service: 'chrome-extension-api', timestamp: new Date().toISOString() });
}
