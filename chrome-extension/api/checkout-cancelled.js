export default function handler(_req, res) {
  res.setHeader('Content-Type', 'text/html; charset=utf-8')
  res.status(200).send(`<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8">
    <title>词析 Pro 未完成付款</title>
  </head>
  <body>
    <h1>付款未完成</h1>
    <p>你可以回到扩展设置页重新开通 Pro。</p>
  </body>
</html>`)
}
