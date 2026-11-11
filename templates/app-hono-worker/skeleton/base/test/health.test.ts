import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { app } from '../src/app';
import { SERVICE_NAME } from '../src/config';

describe('health', () => {
  it('reports the service', async () => {
    const response = await app.request('/health', {}, env);
    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({
      status: 'ok',
      service: SERVICE_NAME,
      environment: env.APP_ENV,
    });
  });

  it('answers the probes', async () => {
    const live = await app.request('/health/live', {}, env);
    expect(await live.json()).toEqual({ alive: true });

    const ready = await app.request('/health/ready', {}, env);
    expect(ready.status).toBe(200);
    expect(await ready.json()).toEqual({ ready: true });
  });

  it('sets a request ID and security headers', async () => {
    const response = await app.request('/health', {}, env);
    expect(response.headers.get('x-request-id')).toBeTruthy();
    expect(response.headers.get('x-content-type-options')).toBe('nosniff');
  });

  it('answers unknown routes with JSON', async () => {
    const response = await app.request('/nowhere', {}, env);
    expect(response.status).toBe(404);
    expect(await response.json()).toEqual({ error: 'Not Found' });
  });
});
