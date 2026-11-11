import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from '../src/app';
import { config } from '../src/config';

const app = createApp();

describe('Health endpoints', () => {
  it('GET /health reports the service as healthy', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      status: 'healthy',
      service: config.name,
      environment: config.environment,
    });
    expect(Number.isNaN(Date.parse(response.body.timestamp))).toBe(false);
  });

  it('GET /health/ready reports readiness', async () => {
    const response = await request(app).get('/health/ready');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ ready: true });
  });

  it('GET /health/live reports liveness', async () => {
    const response = await request(app).get('/health/live');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ alive: true });
  });
});

describe('API endpoints', () => {
  it('GET /api returns the welcome message', async () => {
    const response = await request(app).get('/api');
    expect(response.status).toBe(200);
    expect(response.body.message).toContain(config.name);
    expect(response.body.version).toBe('1.0.0');
  });

  it('GET /api/example returns example data', async () => {
    const response = await request(app).get('/api/example');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ data: 'Example endpoint' });
  });
});

describe('Error handling', () => {
  it('returns 404 as JSON for unknown routes', async () => {
    const response = await request(app).get('/unknown-route');
    expect(response.status).toBe(404);
    expect(response.body).toEqual({ error: 'Not Found' });
  });

  it('returns 400 as JSON when the request body is not valid JSON', async () => {
    const response = await request(app)
      .post('/api')
      .set('Content-Type', 'application/json')
      .send('{"broken"');
    expect(response.status).toBe(400);
    expect(response.body.error).toEqual(expect.any(String));
  });
});
