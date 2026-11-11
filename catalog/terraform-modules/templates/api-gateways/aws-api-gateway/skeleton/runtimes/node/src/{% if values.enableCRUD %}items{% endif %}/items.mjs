import { randomUUID } from 'node:crypto';
import { HttpError, json, noContent, parseObject } from '../router.mjs';

const notFound = () => new HttpError(404, 'Item not found');

// Handlers of the /items endpoints on top of a store with
// list(), get(id), put(item) and delete(id).
export function itemRoutes(store) {
  return {
    'GET /items': async () => json(200, { items: await store.list() }),

    'POST /items': async event => {
      const now = new Date().toISOString();
      const item = {
        ...parseObject(event),
        id: randomUUID(),
        createdAt: now,
        updatedAt: now,
      };
      await store.put(item);
      return json(201, item);
    },

    'GET /items/{id}': async event => {
      const item = await store.get(event.pathParameters.id);
      if (!item) {
        throw notFound();
      }
      return json(200, item);
    },

    'PUT /items/{id}': async event => {
      const attributes = parseObject(event);
      const existing = await store.get(event.pathParameters.id);
      if (!existing) {
        throw notFound();
      }
      const item = {
        ...attributes,
        id: existing.id,
        createdAt: existing.createdAt,
        updatedAt: new Date().toISOString(),
      };
      await store.put(item);
      return json(200, item);
    },

    'DELETE /items/{id}': async event => {
      if (!(await store.delete(event.pathParameters.id))) {
        throw notFound();
      }
      return noContent();
    },
  };
}
