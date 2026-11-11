'use strict';

// Placeholder handler. Terraform deploys it until a real function package is
// supplied (see docs/infrastructure.md). It shows the contract between the
// infrastructure and the function: the environment variables it reads and the
// headers it receives.

const functions = require('@google-cloud/functions-framework');

const list = (value) =>
  (value || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

const allowedOrigins = list(process.env.CORS_ALLOWED_ORIGINS);
const allowedCallers = list(process.env.ALLOWED_CALLERS);

// The gateway forwards OPTIONS requests unauthenticated; CORS is answered here.
function applyCors(req, res) {
  const origin = req.get('Origin');
  if (!origin || allowedOrigins.length === 0) {
    return;
  }
  if (allowedOrigins.includes('*')) {
    res.set('Access-Control-Allow-Origin', '*');
  } else if (allowedOrigins.includes(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
    res.set('Vary', 'Origin');
  } else {
    return;
  }
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.set(
    'Access-Control-Allow-Headers',
    req.get('Access-Control-Request-Headers') || 'Authorization, Content-Type, x-api-key',
  );
  res.set('Access-Control-Max-Age', '3600');
}

// The gateway passes the verified token claims, base64url encoded, in
// X-Apigateway-Api-Userinfo.
function caller(req) {
  const header = req.get('X-Apigateway-Api-Userinfo');
  if (!header) {
    return null;
  }
  try {
    return JSON.parse(Buffer.from(header, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
}

functions.http('handler', (req, res) => {
  applyCors(req, res);
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  const claims = caller(req);
  if (allowedCallers.length > 0 && !(claims && allowedCallers.includes(claims.email))) {
    res.status(403).json({ error: 'caller is not allowed' });
    return;
  }

  if (process.env.API_TYPE === 'graphql') {
    res.status(200).json({
      errors: [{ message: 'Placeholder function: no GraphQL schema is deployed yet.' }],
    });
    return;
  }

  res.status(200).json({
    message: 'Placeholder function. Supply a function package to replace it.',
    service: process.env.K_SERVICE || null,
    revision: process.env.K_REVISION || null,
    environment: process.env.ENVIRONMENT || null,
    method: req.method,
    path: req.path,
    caller: claims ? claims.email || claims.sub || null : null,
  });
});
