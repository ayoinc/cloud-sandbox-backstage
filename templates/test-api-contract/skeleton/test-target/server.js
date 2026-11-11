/**
 * A small API that honours openapi/openapi.yaml, so the contract tests have
 * something to pass against before a real API is pointed at.
 *
 *   node test-target/server.js     # listens on PORT (default 3000)
 */
const http = require('node:http');
const { randomUUID } = require('node:crypto');

const port = Number(process.env.PORT || 3000);
const records = [];
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_BODY_BYTES = 64 * 1024;

function send(res, status, body, type = 'application/json') {
  res.writeHead(status, { 'Content-Type': type });
  res.end(JSON.stringify(body));
}

const problem = (res, status, title, detail) =>
  send(res, status, { title, status, detail }, 'application/problem+json');

/** Why `body` is not a NewRecord, or undefined when it is one. */
function invalid(body) {
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return 'The body must be a JSON object.';
  }
  const extra = Object.keys(body).filter(
    key => !['name', 'amountMinor', 'currency'].includes(key),
  );
  if (extra.length > 0) {
    return `Unknown properties: ${extra.join(', ')}.`;
  }
  const { name, amountMinor, currency } = body;
  if (typeof name !== 'string' || name.length < 1 || name.length > 80) {
    return 'name must be a string of 1 to 80 characters.';
  }
  if (!Number.isInteger(amountMinor) || amountMinor < 0 || amountMinor > 1e9) {
    return 'amountMinor must be a whole number from 0 to 1000000000.';
  }
  if (typeof currency !== 'string' || !/^[A-Z]{3}$/.test(currency)) {
    return 'currency must be three capital letters.';
  }
  return undefined;
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', chunk => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(new Error('too large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const path = url.pathname;

  if (path === '/health' && req.method === 'GET') {
    return send(res, 200, { status: 'ok' });
  }

  if (path === '/records' && req.method === 'GET') {
    const raw = url.searchParams.get('limit');
    const limit = raw === null ? 20 : Number(raw);
    if (raw !== null && (!/^[0-9]+$/.test(raw) || limit < 1 || limit > 100)) {
      return problem(res, 400, 'Invalid limit', 'limit must be 1 to 100.');
    }
    return send(res, 200, { items: records.slice(0, limit) });
  }

  if (path === '/records' && req.method === 'POST') {
    if (!/^application\/json\b/i.test(req.headers['content-type'] || '')) {
      return problem(res, 415, 'Unsupported media type', 'Send JSON.');
    }
    let body;
    try {
      body = JSON.parse(await readBody(req));
    } catch {
      return problem(res, 400, 'Invalid body', 'The body is not valid JSON.');
    }
    const reason = invalid(body);
    if (reason) {
      return problem(res, 400, 'Invalid record', reason);
    }
    const record = {
      id: randomUUID(),
      name: body.name,
      amountMinor: body.amountMinor,
      currency: body.currency,
      createdAt: new Date().toISOString(),
    };
    records.push(record);
    // The sample keeps its memory bounded however long it runs.
    if (records.length > 1000) {
      records.shift();
    }
    return send(res, 201, record);
  }

  const match = /^\/records\/([^/]+)$/.exec(path);
  if (match && req.method === 'GET') {
    if (!UUID.test(match[1])) {
      return problem(res, 400, 'Invalid id', 'id must be a UUID.');
    }
    const record = records.find(item => item.id === match[1].toLowerCase());
    return record
      ? send(res, 200, record)
      : problem(res, 404, 'Not found', 'There is no such record.');
  }

  // A known resource asked for in a way it does not offer.
  const allowed =
    path === '/health' || match ? 'GET' : path === '/records' && 'GET, POST';
  if (allowed) {
    res.setHeader('Allow', allowed);
    return problem(res, 405, 'Method not allowed', `Use ${allowed}.`);
  }
  return problem(res, 404, 'Not found', 'There is no such resource.');
});

server.listen(port, '127.0.0.1', () => {
  console.log(`Sample API listening on http://127.0.0.1:${port}`);
});
