const http = require('node:http');

const SERVICE = '${{ values.name }}';

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

function createServer() {
  return http.createServer((req, res) => {
    const { pathname } = new URL(req.url, 'http://localhost');
    if (req.method === 'GET' && pathname === '/') {
      send(res, 200, { service: SERVICE, message: `Hello from ${SERVICE}` });
    } else if (req.method === 'GET' && pathname === '/health') {
      send(res, 200, { status: 'healthy' });
    } else {
      send(res, 404, { error: 'Not Found' });
    }
  });
}

module.exports = { SERVICE, createServer };
