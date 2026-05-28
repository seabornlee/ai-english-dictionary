export default function handler(req, res) {
  const sessionId = req.query.session_id || ''
  res.setHeader('Content-Type', 'text/html; charset=utf-8')
  res.status(200).send(`<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8">
    <title>词析 Pro 已开通</title>
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 40px; line-height: 1.6; }
      code { display: block; padding: 12px; background: #f5f5f5; border-radius: 8px; word-break: break-all; }
    </style>
  </head>
  <body>
    <h1>词析 Pro 已开通</h1>
    <p>请复制下面的 Checkout Session ID，回到扩展设置页粘贴并点击“激活 Pro”。</p>
    <code>${escapeHtml(sessionId)}</code>
  </body>
</html>`)
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}
