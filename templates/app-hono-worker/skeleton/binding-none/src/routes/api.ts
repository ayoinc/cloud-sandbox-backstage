import { Hono } from 'hono';
import { z } from 'zod';
import type { AppEnv } from '../app';
import { SERVICE_NAME } from '../config';
import { jsonBody } from '../validation';

const echoInput = z.strictObject({
  message: z.string().trim().min(1).max(500),
});

export const api = new Hono<AppEnv>();

api.get('/', (c) => c.json({ message: `Welcome to ${SERVICE_NAME}` }));

// An example of a validated JSON body: replace it with your own routes.
api.post('/echo', jsonBody(echoInput), (c) => {
  const { message } = c.req.valid('json');
  return c.json({ message, length: message.length });
});

/** The Worker has no binding to wait for. */
export async function isReady(_env: Env): Promise<boolean> {
  return true;
}
