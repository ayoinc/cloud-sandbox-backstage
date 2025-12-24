{%- if values.enable_mock_api %}
import { http, HttpResponse } from 'msw';

export const handlers = [
  // Health check endpoint
  http.get('/api/health', () => {
    return HttpResponse.json({ status: 'ok', timestamp: new Date().toISOString() });
  }),

  // Example: GET items
  http.get('/api/items', () => {
    return HttpResponse.json([
      { id: '1', name: 'Item 1', description: 'First item' },
      { id: '2', name: 'Item 2', description: 'Second item' },
      { id: '3', name: 'Item 3', description: 'Third item' },
    ]);
  }),

  // Example: GET single item
  http.get('/api/items/:id', ({ params }) => {
    const { id } = params;
    return HttpResponse.json({
      id,
      name: `Item ${id}`,
      description: `Description for item ${id}`,
    });
  }),

  // Example: POST create item
  http.post('/api/items', async ({ request }) => {
    const body = await request.json() as { name: string; description?: string };
    return HttpResponse.json(
      {
        id: crypto.randomUUID(),
        name: body.name,
        description: body.description || '',
        createdAt: new Date().toISOString(),
      },
      { status: 201 }
    );
  }),

  // Example: PUT update item
  http.put('/api/items/:id', async ({ params, request }) => {
    const { id } = params;
    const body = await request.json() as { name?: string; description?: string };
    return HttpResponse.json({
      id,
      ...body,
      updatedAt: new Date().toISOString(),
    });
  }),

  // Example: DELETE item
  http.delete('/api/items/:id', () => {
    return new HttpResponse(null, { status: 204 });
  }),

  // Error simulation endpoint
  http.get('/api/error', () => {
    return HttpResponse.json(
      { message: 'Something went wrong', code: 'INTERNAL_ERROR' },
      { status: 500 }
    );
  }),

  // 401 Unauthorized endpoint
  http.get('/api/protected', () => {
    return HttpResponse.json(
      { message: 'Unauthorized', code: 'UNAUTHORIZED' },
      { status: 401 }
    );
  }),
];
{%- endif %}
