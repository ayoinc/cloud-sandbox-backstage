/**
 * Minimal two-page site used as the test target when no deployed
 * environment is available (CI on a fresh repository, local smoke runs).
 *
 *   node demo-app/server.js        # listens on PORT (default 3100)
 */
const http = require('node:http');

const port = Number(process.env.PORT || 3100);

const pages = {
  '/': {
    title: 'Demo App - Home',
    heading: 'Welcome',
    body: 'This page is served by the bundled demo app.',
  },
  '/about': {
    title: 'Demo App - About',
    heading: 'About',
    body: 'Replace the demo app with your own application under test.',
  },
};

function render({ title, heading, body }) {
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${title}</title>
  </head>
  <body>
    <header>
      <nav aria-label="Main">
        <a href="/about">About</a>
        <a href="/">Home</a>
      </nav>
    </header>
    <main>
      <h1>${heading}</h1>
      <p>${body}</p>
    </main>
  </body>
</html>`;
}

const server = http.createServer((req, res) => {
  const { pathname } = new URL(req.url, `http://${req.headers.host}`);
  const page = pages[pathname];
  if (!page) {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Not found');
    return;
  }
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(render(page));
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Demo app listening on http://127.0.0.1:${port}`);
});
