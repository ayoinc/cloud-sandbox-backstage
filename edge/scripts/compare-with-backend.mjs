// Checks that the Worker answers catalog requests exactly like the Backstage
// backend that produced its catalog. Sends each request to both and compares
// the JSON, following paging cursors to the end on each side.
//
// Run `yarn catalog:sync` against the Worker first. The sync leaves the
// pipeline backend's database behind, and this script starts that backend
// again on it, so both sides hold the very same entities.
//
//   EDGE_URL           (default http://localhost:8787) the Worker; it must
//                      allow guest sign-in, as `yarn dev` does
//   PIPELINE_DATA_DIR  (default edge/.wrangler/pipeline) where the sync kept
//                      its data
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { isDeepStrictEqual } from 'node:util';
import { startBackend } from './pipeline/backend.mjs';
import { dataDirFor } from './pipeline/settings.mjs';

const EDGE = process.env.EDGE_URL ?? 'http://localhost:8787';
const MAX_PAGES = 100;

const dataDir = dataDirFor('pipeline');
if (!existsSync(join(dataDir, 'catalog.sqlite'))) {
  console.error(
    `There is no synced catalog in ${dataDir}. Run \`yarn catalog:sync\` against the Worker first.`,
  );
  process.exit(1);
}
const pipelineBackend = await startBackend({
  dataDir,
  githubToken: process.env.PORTAL_GITHUB_TOKEN || undefined,
});
const BACKEND = pipelineBackend.url;

async function guestToken() {
  const response = await fetch(`${EDGE}/api/auth/guest/refresh`, {
    headers: { 'x-requested-with': 'XMLHttpRequest' },
  });
  if (!response.ok) {
    throw new Error(`Guest sign-in failed at ${EDGE}: ${response.status}`);
  }
  return (await response.json()).backstageIdentity.token;
}

const tokens = {
  [BACKEND]: pipelineBackend.token,
  [EDGE]: await guestToken(),
};

async function call(base, { path, body }) {
  const response = await fetch(`${base}/api/catalog${path}`, {
    method: body ? 'POST' : 'GET',
    headers: {
      authorization: `Bearer ${tokens[base]}`,
      ...(body && { 'content-type': 'application/json' }),
    },
    body: body && JSON.stringify(body),
  });
  const json = await response.json();
  // Stack traces are server-specific. Rejected input (400) is compared by
  // status and error name only: each side words its validation messages.
  if (json?.error) {
    delete json.error.stack;
    delete json.error.cause;
    if (response.status === 400) {
      delete json.error.message;
    }
  }
  return {
    status: response.status,
    hasNextLink: response.headers.has('link'),
    json,
  };
}

/**
 * The parts of a response that must match. Paging cursors are reduced to
 * presence, since each side encodes its own, and ancestry items are sorted,
 * since their order carries no meaning.
 */
function comparable({ status, hasNextLink, json }) {
  if (json?.rootEntityRef) {
    const ref = item =>
      `${item.entity.kind}:${item.entity.metadata.namespace}/${item.entity.metadata.name}`;
    return {
      status,
      json: {
        ...json,
        items: json.items
          .map(item => ({
            ...item,
            parentEntityRefs: item.parentEntityRefs.toSorted(),
          }))
          .toSorted((a, b) => ref(a).localeCompare(ref(b))),
      },
    };
  }
  if (!json?.pageInfo) {
    return { status, hasNextLink, json };
  }
  return {
    status,
    json: {
      ...json,
      pageInfo: {
        hasNext: Boolean(json.pageInfo.nextCursor),
        hasPrev: Boolean(json.pageInfo.prevCursor),
      },
    },
  };
}

function nextPage(request, cursor, direction) {
  if (request.body) {
    return { path: request.path, body: { cursor, limit: request.body.limit } };
  }
  const limit = new URLSearchParams(request.path.split('?')[1]).get('limit');
  const params = new URLSearchParams({ cursor, ...(limit && { limit }) });
  return { path: `${request.path.split('?')[0]}?${params}`, direction };
}

const byQuery = (body, walkBack = false) => ({
  path: '/entities/by-query',
  body,
  walkBack,
});

const cases = {
  'facets: all kinds': { path: '/entity-facets?facet=kind' },
  'facets: two facets with a filter': {
    path: '/entity-facets?facet=spec.type&facet=spec.lifecycle&filter=kind=component',
  },
  'facets: AND filter': {
    path: '/entity-facets?facet=metadata.tags&filter=kind=component,spec.lifecycle=production',
  },
  'facets: OR of two filters': {
    path: '/entity-facets?facet=spec.owner&filter=kind=api&filter=kind=resource',
  },
  'facets: field exists': {
    path: '/entity-facets?facet=kind&filter=metadata.annotations.backstage.io/techdocs-ref',
  },
  'facets: missing facet parameter': { path: '/entity-facets' },
  'facets (POST): simple query': {
    path: '/entity-facets',
    body: {
      facets: ['spec.owner', 'metadata.namespace'],
      query: { kind: 'component' },
    },
  },
  'facets (POST): $all, $in, $not, $hasPrefix': {
    path: '/entity-facets',
    body: {
      facets: ['kind', 'spec.type'],
      query: {
        $all: [
          { kind: { $in: ['component', 'api'] } },
          { $not: { 'spec.lifecycle': 'experimental' } },
          { 'metadata.name': { $hasPrefix: 'a' } },
        ],
      },
    },
  },
  'facets (POST): $any and $exists false': {
    path: '/entity-facets',
    body: {
      facets: ['kind'],
      query: {
        $any: [{ kind: 'domain' }, { 'spec.system': { $exists: false } }],
      },
    },
  },
  'facets (POST): relation target': {
    path: '/entity-facets',
    body: {
      facets: ['kind'],
      query: {
        relations: {
          $contains: {
            type: 'ownedBy',
            targetRef: 'group:default/platform-team',
          },
        },
      },
    },
  },
  'facets (POST): invalid predicate': {
    path: '/entity-facets',
    body: { facets: ['kind'], query: { kind: { $bogus: 1 } } },
  },
  'query: components by name, every page': byQuery({
    query: { kind: 'component' },
    orderBy: [{ field: 'metadata.name', order: 'asc' }],
    limit: 20,
  }),
  'query: descending, every page then back again': byQuery(
    {
      query: { kind: 'component' },
      orderBy: [{ field: 'metadata.name', order: 'desc' }],
      limit: 25,
    },
    true,
  ),
  'query: no order, every page': byQuery({ query: { kind: 'api' }, limit: 7 }),
  'query: ordered by a field some entities lack': byQuery({
    orderBy: [{ field: 'spec.type', order: 'asc' }],
    limit: 50,
  }),
  'query: text filter on the sort field': byQuery({
    query: { kind: 'component' },
    orderBy: [{ field: 'metadata.name', order: 'asc' }],
    fullTextFilter: { term: 'aws', fields: ['metadata.name'] },
    limit: 10,
  }),
  'query: text filter across fields': byQuery({
    orderBy: [{ field: 'metadata.name', order: 'asc' }],
    fullTextFilter: {
      term: 'Kafka',
      fields: ['metadata.name', 'metadata.title', 'metadata.description'],
    },
    limit: 10,
  }),
  'query: field projection with dotted keys': byQuery({
    query: { kind: 'component' },
    orderBy: [{ field: 'metadata.name', order: 'asc' }],
    fields: [
      'kind',
      'metadata.name',
      'metadata.annotations.backstage.io/techdocs-ref',
      'spec.owner',
      'relations',
    ],
    limit: 30,
  }),
  'query: offset': byQuery({
    query: { kind: 'template' },
    orderBy: [{ field: 'metadata.name', order: 'asc' }],
    limit: 10,
    offset: 15,
  }),
  'query: total count excluded': byQuery({
    query: { kind: 'group' },
    limit: 5,
    totalItems: 'exclude',
  }),
  'query: zero limit': byQuery({ query: { kind: 'system' }, limit: 0 }),
  'query (GET): filter and order, every page': {
    path: '/entities/by-query?filter=kind=api&orderField=metadata.name,asc&limit=8',
    walkBack: true,
  },
  'query (GET): text filter': {
    path: '/entities/by-query?filter=kind=component&orderField=metadata.name,desc&fullTextFilterTerm=apache&fullTextFilterFields=metadata.name,metadata.title&limit=5',
  },
  'by-refs: found, missing and repeated': {
    path: '/entities/by-refs',
    body: {
      entityRefs: [
        'component:default/apache-kafka',
        'component:default/does-not-exist',
        'group:default/platform-team',
        'component:default/apache-kafka',
      ],
    },
  },
  'by-refs: with fields': {
    path: '/entities/by-refs',
    body: {
      entityRefs: ['component:default/apache-airflow', 'api:default/nope'],
      fields: ['kind', 'metadata.name', 'metadata.namespace'],
    },
  },
  'by-name: found': {
    path: '/entities/by-name/component/default/apache-kafka',
  },
  'by-name: mixed case': {
    path: '/entities/by-name/Component/default/Apache-Kafka',
  },
  'by-name: missing': { path: '/entities/by-name/component/default/nope' },
  'ancestry: component': {
    path: '/entities/by-name/component/default/apache-kafka/ancestry',
  },
  'ancestry: template': {
    path: '/entities/by-name/template/default/ansible-playbook-template/ancestry',
  },
  'ancestry: missing': {
    path: '/entities/by-name/component/default/nope/ancestry',
  },
  'list: groups': { path: '/entities?filter=kind=group' },
  'list: ordered page': {
    path: '/entities?filter=kind=component&order=asc:metadata.name&limit=10&offset=5',
  },
  'list: descending by a field some entities lack': {
    path: '/entities?filter=kind=component&filter=kind=api&order=desc:spec.lifecycle&fields=kind,metadata.name,spec.lifecycle',
  },
  'list: default order with fields': {
    path: '/entities?fields=kind,metadata.name&limit=40',
  },
};

async function compare(name, request) {
  const differences = [];
  let pages = 0;
  let requests = { [BACKEND]: request, [EDGE]: request };
  const cursorKey = { forward: 'nextCursor', back: 'prevCursor' };
  let direction = 'forward';

  while (requests && pages < MAX_PAGES) {
    const [backend, edge] = await Promise.all([
      call(BACKEND, requests[BACKEND]),
      call(EDGE, requests[EDGE]),
    ]);
    pages += 1;
    if (!isDeepStrictEqual(comparable(backend), comparable(edge))) {
      differences.push({ page: pages, direction, backend, edge });
      break;
    }
    let cursor = backend.json?.pageInfo?.[cursorKey[direction]];
    if (!cursor && direction === 'forward' && request.walkBack) {
      direction = 'back';
      cursor = backend.json?.pageInfo?.prevCursor;
    }
    requests = cursor && {
      [BACKEND]: nextPage(request, cursor),
      [EDGE]: nextPage(request, edge.json.pageInfo[cursorKey[direction]]),
    };
  }
  return { name, pages, differences };
}

let failed = 0;
for (const [name, request] of Object.entries(cases)) {
  const { pages, differences } = await compare(name, request);
  if (differences.length) {
    failed += 1;
    const [{ page, direction, backend, edge }] = differences;
    console.log(`DIFFERENT  ${name} (page ${page}, ${direction})`);
    console.log(
      `  backend: ${JSON.stringify(comparable(backend)).slice(0, 600)}`,
    );
    console.log(`  edge:    ${JSON.stringify(comparable(edge)).slice(0, 600)}`);
  } else {
    console.log(`same       ${name}${pages > 1 ? ` (${pages} pages)` : ''}`);
  }
}
console.log(
  `\n${Object.keys(cases).length - failed} of ${
    Object.keys(cases).length
  } cases identical`,
);
await pipelineBackend.stop();
process.exit(failed ? 1 : 0);
