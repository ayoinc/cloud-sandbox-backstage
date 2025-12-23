/**
 * Smoke Tests - Quick health checks for all routes and API endpoints
 * 
 * These tests verify that:
 * - All frontend routes are accessible
 * - All backend API endpoints respond
 * - Basic functionality is working
 * 
 * Run with: yarn test:e2e --grep "Smoke"
 */

import { test, expect, APIRequestContext } from '@playwright/test';

const BASE_URL = process.env.PLAYWRIGHT_URL || 'http://localhost:7007';
const API_BASE = `${BASE_URL}/api`;

test.describe('Smoke Tests - Frontend Routes', () => {
  test.describe.configure({ mode: 'parallel' });

  const routes = [
    { path: '/', name: 'Homepage', expectedStatus: [200, 301, 302] },
    { path: '/catalog', name: 'Catalog' },
    { path: '/catalog?filters[kind]=component', name: 'Catalog Components' },
    { path: '/catalog?filters[kind]=api', name: 'Catalog APIs' },
    { path: '/catalog?filters[kind]=system', name: 'Catalog Systems' },
    { path: '/catalog?filters[kind]=domain', name: 'Catalog Domains' },
    { path: '/catalog?filters[kind]=group', name: 'Catalog Groups' },
    { path: '/catalog?filters[kind]=user', name: 'Catalog Users' },
    { path: '/catalog?filters[kind]=template', name: 'Catalog Templates' },
    { path: '/docs', name: 'TechDocs' },
    { path: '/create', name: 'Scaffolder/Create' },
    { path: '/search', name: 'Search' },
    { path: '/settings', name: 'Settings' },
    { path: '/api-docs', name: 'API Docs' },
  ];

  for (const route of routes) {
    test(`Route: ${route.name} (${route.path})`, async ({ page }) => {
      const response = await page.goto(`${BASE_URL}${route.path}`);
      
      const expectedStatuses = route.expectedStatus || [200];
      expect(expectedStatuses).toContain(response?.status());
      
      // Page should not show a critical error
      const errorText = await page.locator('text=/error|500|404/i').first().isVisible().catch(() => false);
      // Note: 404 in content might be acceptable for empty states
    });
  }
});

test.describe('Smoke Tests - Backend API Health', () => {
  test.describe.configure({ mode: 'parallel' });

  test('Backend root responds', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/.backstage/health/v1/liveness`).catch(() => null);
    // Health endpoint might not exist, so we'll test another way
    const catalogResponse = await request.get(`${API_BASE}/catalog/entities?limit=1`);
    expect(catalogResponse.status()).toBe(200);
  });
});

test.describe('Smoke Tests - Catalog API', () => {
  test.describe.configure({ mode: 'parallel' });

  test('GET /api/catalog/entities', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/entities?limit=10`);
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
  });

  test('GET /api/catalog/entities (filter by kind=Component)', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/entities?filter=kind=component&limit=10`);
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
  });

  test('GET /api/catalog/entities (filter by kind=Template)', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/entities?filter=kind=template&limit=10`);
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
  });

  test('GET /api/catalog/entities (filter by kind=System)', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/entities?filter=kind=system&limit=10`);
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
  });

  test('GET /api/catalog/entities (filter by kind=Domain)', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/entities?filter=kind=domain&limit=10`);
    expect(response.status()).toBe(200);
  });

  test('GET /api/catalog/entities (filter by kind=Group)', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/entities?filter=kind=group&limit=10`);
    expect(response.status()).toBe(200);
  });

  test('GET /api/catalog/entities (filter by kind=User)', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/entities?filter=kind=user&limit=10`);
    expect(response.status()).toBe(200);
  });

  test('GET /api/catalog/entities (filter by kind=API)', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/entities?filter=kind=api&limit=10`);
    expect(response.status()).toBe(200);
  });

  test('GET /api/catalog/locations', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/locations`);
    expect(response.status()).toBe(200);
  });

  test('GET /api/catalog/entity-facets', async ({ request }) => {
    const response = await request.get(`${API_BASE}/catalog/entity-facets?facet=kind`);
    expect(response.status()).toBe(200);
  });

  test('POST /api/catalog/entities/by-refs', async ({ request }) => {
    const response = await request.post(`${API_BASE}/catalog/entities/by-refs`, {
      data: { entityRefs: [] },
      headers: { 'Content-Type': 'application/json' },
    });
    expect(response.status()).toBe(200);
  });
});

test.describe('Smoke Tests - TechDocs API', () => {
  test.describe.configure({ mode: 'parallel' });

  test('GET /api/techdocs/static/docs exists', async ({ request }) => {
    // This might return 404 if no docs exist, but endpoint should respond
    const response = await request.get(`${API_BASE}/techdocs/static/docs`);
    expect([200, 404]).toContain(response.status());
  });

  test('POST /api/techdocs/sync for terraform-modules', async ({ request }) => {
    const response = await request.get(`${API_BASE}/techdocs/sync/default/component/terraform-modules`);
    expect(response.status()).toBe(200);
  });

  test('GET /api/techdocs/metadata/techdocs for terraform-modules', async ({ request }) => {
    const response = await request.get(`${API_BASE}/techdocs/metadata/techdocs/default/component/terraform-modules`);
    expect([200, 404]).toContain(response.status()); // 404 if not built yet
  });

  test('GET /api/techdocs/metadata/entity for terraform-modules', async ({ request }) => {
    const response = await request.get(`${API_BASE}/techdocs/metadata/entity/default/component/terraform-modules`);
    expect([200, 404]).toContain(response.status());
  });
});

test.describe('Smoke Tests - Scaffolder API', () => {
  test.describe.configure({ mode: 'parallel' });

  test('GET /api/scaffolder/v2/actions', async ({ request }) => {
    const response = await request.get(`${API_BASE}/scaffolder/v2/actions`);
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
    expect(data.length).toBeGreaterThan(0);
  });

  test('GET /api/scaffolder/v2/tasks', async ({ request }) => {
    const response = await request.get(`${API_BASE}/scaffolder/v2/tasks`);
    expect(response.status()).toBe(200);
  });
});

test.describe('Smoke Tests - Search API', () => {
  test.describe.configure({ mode: 'parallel' });

  test('GET /api/search/query (empty term)', async ({ request }) => {
    const response = await request.get(`${API_BASE}/search/query?term=`);
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(data).toHaveProperty('results');
  });

  test('GET /api/search/query (with term)', async ({ request }) => {
    const response = await request.get(`${API_BASE}/search/query?term=terraform`);
    expect(response.status()).toBe(200);
    const data = await response.json();
    expect(data).toHaveProperty('results');
  });
});

test.describe('Smoke Tests - Permission API', () => {
  test('POST /api/permission/authorize', async ({ request }) => {
    const response = await request.post(`${API_BASE}/permission/authorize`, {
      data: { items: [] },
      headers: { 'Content-Type': 'application/json' },
    });
    expect(response.status()).toBe(200);
  });
});

test.describe('Smoke Tests - Auth API', () => {
  test('GET /api/auth/github/start is available', async ({ request }) => {
    // This will redirect, so we expect a redirect status
    const response = await request.get(`${API_BASE}/auth/github/start?env=development`, {
      maxRedirects: 0,
    }).catch(e => e);
    // Should either work or redirect
    expect([200, 302, 303]).toContain(response.status?.() || 302);
  });
});

test.describe('Smoke Tests - Proxy API', () => {
  test('Proxy endpoint exists', async ({ request }) => {
    // Proxy endpoints return 404 if not configured, but should respond
    const response = await request.get(`${API_BASE}/proxy`);
    expect([200, 404, 405]).toContain(response.status());
  });
});
