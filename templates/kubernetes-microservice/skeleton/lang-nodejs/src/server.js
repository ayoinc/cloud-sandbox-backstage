const http = require('node:http');

const SERVICE = '${{ values.name }}';

function createServer() {
  let requests = 0;

  return http.createServer((req, res) => {
    requests += 1;
    const json = (status, body) => {
      res.writeHead(status, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(body));
    };

    const { pathname } = new URL(req.url, 'http://localhost');
    if (req.method !== 'GET') {
      json(404, { error: 'Not Found' });
    } else if (pathname === '/') {
      json(200, {
        service: SERVICE,
        environment: process.env.ENVIRONMENT ?? 'local',
      });
    } else if (pathname === '/health') {
      json(200, { status: 'healthy' });
    } else if (pathname === '/ready') {
      json(200, { status: 'ready' });
    } else if (pathname === '/metrics') {
      // Prometheus text exposition format
      res.writeHead(200, { 'Content-Type': 'text/plain; version=0.0.4' });
      res.end(
        '# HELP http_requests_total Requests handled by the service.\n' +
          '# TYPE http_requests_total counter\n' +
          `http_requests_total ${requests}\n`,
      );
    } else {
      json(404, { error: 'Not Found' });
    }
  });
}

module.exports = { SERVICE, createServer };
