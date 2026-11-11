import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';
import { app } from '../src/app';

const post = (body: string) =>
  app.request(
    '/api/echo',
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body,
    },
    env,
  );

describe('api', () => {
  it('welcomes', async () => {
    const response = await app.request('/api', {}, env);
    expect(response.status).toBe(200);
    expect(await response.json()).toHaveProperty('message');
  });

  it('echoes a valid message', async () => {
    const response = await post(JSON.stringify({ message: ' hello ' }));
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ message: 'hello', length: 5 });
  });

  it('rejects invalid input', async () => {
    expect((await post('message=hello')).status).toBe(400);
    expect((await post(JSON.stringify({ message: '' }))).status).toBe(422);
    expect((await post(JSON.stringify({ text: 'hello' }))).status).toBe(422);
  });
});
