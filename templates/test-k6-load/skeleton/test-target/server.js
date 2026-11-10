/**
 * Minimal HTTP target for smoke runs when no deployed environment is
 * available (CI on a fresh repository, trying the scripts locally).
 *
 *   node test-target/server.js     # listens on PORT (default 3000)
 */
const http = require('node:http');

const port = Number(process.env.PORT || 3000);

const routes = {
  '/': { status: 'ok', service: 'k6-test-target' },
  '/api/health': { status: 'healthy' },
  '/api/users': { users: [] },
  '/api/products': { products: [] },
};

const server = http.createServer((req, res) => {
  const { pathname } = new URL(req.url, `http://${req.headers.host}`);
  const body = routes[pathname];
  res.writeHead(body ? 200 : 404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body || { error: 'not found' }));
});

server.listen(port, '127.0.0.1', () => {
  console.log(`k6 test target listening on http://127.0.0.1:${port}`);
});
