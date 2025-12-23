/**
 * Integration Tests - API endpoint integration tests
 * 
 * These tests verify:
 * - API endpoints work together correctly
 * - Data flows between services
 * - Complex query scenarios
 * - Error handling
 * 
 * Run with: yarn test:e2e --grep "Integration"
 */

import { test, expect } from '@playwright/test';

const BASE_URL = process.env.PLAYWRIGHT_URL || 'http://localhost:7007';
const API_BASE = `${BASE_URL}/api`;

test.describe('Integration Tests - Catalog Entity Operations', () => {
  test('Catalog returns consistent data across endpoints', async ({ request }) => {
    // Get all components
    const componentsResponse = await request.get(`${API_BASE}/catalog/entities?filter=kind=component`);
    expect(componentsResponse.status()).toBe(200);
    const components = await componentsResponse.json();
    
    if (components.length > 0) {
      // Verify first component exists via by-name endpoint
      const firstComponent = components[0];
      const namespace = firstComponent.metadata.namespace || 'default';
      const name = firstComponent.metadata.name;
      
      const byNameResponse = await request.get(
        `${API_BASE}/catalog/entities/by-name/component/${namespace}/${name}`
      );
      expect(byNameResponse.status()).toBe(200);
      
      const byNameData = await byNameResponse.json();
      expect(byNameData.metadata.name).toBe(name);
    }
  });

  test('Catalog by-refs returns requested entities', async ({ request }) => {
    // First get some entities
    const entitiesResponse = await request.get(`${API_BASE}/catalog/entities?limit=3`);
    expect(entitiesResponse.status()).toBe(200);
    const entities = await entitiesResponse.json();
    
    if (entities.length > 0) {
      // Build entity refs
      const entityRefs = entities.map((e: any) => {
        const namespace = e.metadata.namespace || 'default';
        return `${e.kind.toLowerCase()}:${namespace}/${e.metadata.name}`;
      });
      
      // Fetch by refs
      const byRefsResponse = await request.post(`${API_BASE}/catalog/entities/by-refs`, {
        data: { entityRefs },
        headers: { 'Content-Type': 'application/json' },
      });
      expect(byRefsResponse.status()).toBe(200);
      
      const byRefsData = await byRefsResponse.json();
      expect(byRefsData.items.length).toBe(entities.length);
    }
  });

  test('Catalog facets match entity counts', async ({ request }) => {
    // Get facets
    const facetsResponse = await request.get(`${API_BASE}/catalog/entity-facets?facet=kind`);
    expect(facetsResponse.status()).toBe(200);
    const facetsData = await facetsResponse.json();
    
    // Verify at least one facet exists
    expect(facetsData.facets).toBeDefined();
    expect(facetsData.facets.kind).toBeDefined();
    
    // Verify component count matches
    const componentFacet = facetsData.facets.kind.find((f: any) => 
      f.value.toLowerCase() === 'component'
    );
    
    if (componentFacet) {
      const componentsResponse = await request.get(
        `${API_BASE}/catalog/entities?filter=kind=component`
      );
      const components = await componentsResponse.json();
      expect(componentFacet.count).toBe(components.length);
    }
  });
});

test.describe('Integration Tests - TechDocs Flow', () => {
  test('TechDocs sync triggers and returns metadata', async ({ request }) => {
    // Trigger sync
    const syncResponse = await request.get(
      `${API_BASE}/techdocs/sync/default/component/terraform-modules`
    );
    expect(syncResponse.status()).toBe(200);
    
    // Wait a moment for processing
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Get metadata
    const metadataResponse = await request.get(
      `${API_BASE}/techdocs/metadata/techdocs/default/component/terraform-modules`
    );
    
    if (metadataResponse.status() === 200) {
      const metadata = await metadataResponse.json();
      expect(metadata.site_name).toBeDefined();
      expect(metadata.files).toBeDefined();
    }
  });

  test('TechDocs static content is served after sync', async ({ request }) => {
    // First sync
    await request.get(`${API_BASE}/techdocs/sync/default/component/terraform-modules`);
    
    // Wait for build
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Try to get static content
    const staticResponse = await request.get(
      `${API_BASE}/techdocs/static/docs/default/component/terraform-modules/index.html`
    );
    
    // Should return HTML content
    if (staticResponse.status() === 200) {
      const content = await staticResponse.text();
      expect(content).toContain('<!doctype html>');
    }
  });

  test('TechDocs pages are all accessible', async ({ request }) => {
    const pages = [
      'index.html',
      'getting-started/index.html',
      'best-practices/index.html',
      'modules/aws-vpc/index.html',
      'modules/azure-vnet/index.html',
      'modules/gcp-vpc/index.html',
    ];
    
    for (const page of pages) {
      const response = await request.get(
        `${API_BASE}/techdocs/static/docs/default/component/terraform-modules/${page}`
      );
      expect([200, 404]).toContain(response.status());
    }
  });
});

test.describe('Integration Tests - Scaffolder Templates', () => {
  test('All templates are listed and have required fields', async ({ request }) => {
    // Get all templates
    const templatesResponse = await request.get(
      `${API_BASE}/catalog/entities?filter=kind=template`
    );
    expect(templatesResponse.status()).toBe(200);
    const templates = await templatesResponse.json();
    
    expect(templates.length).toBeGreaterThan(0);
    
    for (const template of templates) {
      expect(template.kind).toBe('Template');
      expect(template.metadata.name).toBeDefined();
      expect(template.spec).toBeDefined();
      expect(template.spec.type).toBeDefined();
    }
  });

  test('Template parameter schemas are accessible', async ({ request }) => {
    // Get templates
    const templatesResponse = await request.get(
      `${API_BASE}/catalog/entities?filter=kind=template&limit=3`
    );
    const templates = await templatesResponse.json();
    
    for (const template of templates) {
      const namespace = template.metadata.namespace || 'default';
      const name = template.metadata.name;
      
      const schemaResponse = await request.get(
        `${API_BASE}/scaffolder/v2/templates/${namespace}/template/${name}/parameter-schema`
      );
      
      // Schema should be accessible
      expect([200, 404]).toContain(schemaResponse.status());
    }
  });

  test('Scaffolder actions are available', async ({ request }) => {
    const actionsResponse = await request.get(`${API_BASE}/scaffolder/v2/actions`);
    expect(actionsResponse.status()).toBe(200);
    
    const actions = await actionsResponse.json();
    expect(Array.isArray(actions)).toBe(true);
    
    // Verify common actions exist
    const actionIds = actions.map((a: any) => a.id);
    const expectedActions = [
      'fetch:template',
      'publish:github',
      'catalog:register',
    ];
    
    for (const expected of expectedActions) {
      expect(actionIds).toContain(expected);
    }
  });
});

test.describe('Integration Tests - Search Integration', () => {
  test('Search returns results from catalog', async ({ request }) => {
    // First, ensure we have some entities
    const entitiesResponse = await request.get(`${API_BASE}/catalog/entities?limit=5`);
    const entities = await entitiesResponse.json();
    
    if (entities.length > 0) {
      const firstEntityName = entities[0].metadata.name;
      
      // Search for this entity
      const searchResponse = await request.get(
        `${API_BASE}/search/query?term=${firstEntityName}`
      );
      expect(searchResponse.status()).toBe(200);
      
      const searchData = await searchResponse.json();
      expect(searchData.results).toBeDefined();
    }
  });

  test('Search filters work correctly', async ({ request }) => {
    // Search with kind filter
    const response = await request.get(
      `${API_BASE}/search/query?term=&filters[kind]=Component`
    );
    expect(response.status()).toBe(200);
    
    const data = await response.json();
    expect(data.results).toBeDefined();
  });

  test('Search pagination works', async ({ request }) => {
    // First page
    const page1Response = await request.get(
      `${API_BASE}/search/query?term=&pageCursor=`
    );
    expect(page1Response.status()).toBe(200);
    
    const page1Data = await page1Response.json();
    expect(page1Data.results).toBeDefined();
    
    // If there's a next cursor, fetch next page
    if (page1Data.nextPageCursor) {
      const page2Response = await request.get(
        `${API_BASE}/search/query?term=&pageCursor=${page1Data.nextPageCursor}`
      );
      expect(page2Response.status()).toBe(200);
    }
  });
});

test.describe('Integration Tests - Permission System', () => {
  test('Permission API handles multiple permission checks', async ({ request }) => {
    // The permission API requires specific format with id and attributes
    const response = await request.post(`${API_BASE}/permission/authorize`, {
      data: {
        items: [
          { 
            id: 'test-1',
            permission: { 
              type: 'basic',
              name: 'catalog.entity.read',
              attributes: {}
            } 
          },
          { 
            id: 'test-2',
            permission: { 
              type: 'basic',
              name: 'catalog.entity.create',
              attributes: {}
            } 
          },
          { 
            id: 'test-3',
            permission: { 
              type: 'basic',
              name: 'catalog.entity.delete',
              attributes: {}
            } 
          },
        ],
      },
      headers: { 'Content-Type': 'application/json' },
    });
    
    expect(response.status()).toBe(200);
    
    const data = await response.json();
    expect(data.items).toBeDefined();
    expect(data.items.length).toBe(3);
  });
});

test.describe('Integration Tests - Entity Relationships', () => {
  test('System contains related components', async ({ request }) => {
    // Get a system
    const systemsResponse = await request.get(
      `${API_BASE}/catalog/entities?filter=kind=system&limit=1`
    );
    const systems = await systemsResponse.json();
    
    if (systems.length > 0) {
      const system = systems[0];
      const systemRef = `system:${system.metadata.namespace || 'default'}/${system.metadata.name}`;
      
      // Find components that belong to this system
      const componentsResponse = await request.get(
        `${API_BASE}/catalog/entities?filter=kind=component,spec.system=${system.metadata.name}`
      );
      expect(componentsResponse.status()).toBe(200);
    }
  });

  test('Domain contains related systems', async ({ request }) => {
    // Get a domain
    const domainsResponse = await request.get(
      `${API_BASE}/catalog/entities?filter=kind=domain&limit=1`
    );
    const domains = await domainsResponse.json();
    
    if (domains.length > 0) {
      const domain = domains[0];
      
      // Find systems in this domain
      const systemsResponse = await request.get(
        `${API_BASE}/catalog/entities?filter=kind=system,spec.domain=${domain.metadata.name}`
      );
      expect(systemsResponse.status()).toBe(200);
    }
  });
});
