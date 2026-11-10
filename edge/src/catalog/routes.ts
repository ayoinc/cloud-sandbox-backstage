import { Hono } from 'hono';
import { decodeJson, encodeJson } from '../encoding';
import { inputError, notFoundError } from '../errors';
import { rawJson } from '../json';
import type { AppEnv } from '../types';
import { parseFilterStrings } from './filter';
import {
  entitiesByRefs,
  entityAncestry,
  entityByName,
  entityFacets,
  listEntities,
  queryEntities,
  type FullTextFilter,
  type OrderField,
  type QueryCursor,
  type QueryEntitiesRequest,
} from './queries';

/** Read side of the Backstage catalog REST API (`/api/catalog`). */
export const catalogRoutes = new Hono<AppEnv>();

const MAX_LIMIT = 1000;
const UNPAGED_BATCH_SIZE = 10_000;

function parseCount(value: unknown, name: string): number | undefined {
  if (value === undefined || value === null || value === '') {
    return undefined;
  }
  const count = Number(value);
  if (!Number.isInteger(count) || count < 0 || count > MAX_LIMIT) {
    throw inputError(
      `Invalid ${name}, expected an integer from 0 to ${MAX_LIMIT}`,
    );
  }
  return count;
}

function parseOrder(order: unknown, source: string): OrderField['order'] {
  if (order !== undefined && order !== 'asc' && order !== 'desc') {
    throw inputError(`Invalid order in ${source}, must be asc or desc`);
  }
  return order;
}

/** Splits repeated and comma-separated query values into one trimmed list. */
const splitValues = (values: string[] | undefined) =>
  (values ?? [])
    .flatMap(value => value.split(','))
    .map(value => value.trim())
    .filter(Boolean);

type Projection = (entity: string | null) => string;

/**
 * Builds a `fields` projection, or `undefined` when every field is wanted.
 * A path part that is not found is joined to the next one, so keys that
 * contain dots (annotations, labels) resolve.
 */
function projection(fields: string[]): Projection | undefined {
  if (!fields.length) {
    return undefined;
  }
  const arrayField = fields.find(field => field.includes('['));
  if (arrayField) {
    throw inputError(
      `Invalid field "${arrayField}", array type fields are not supported`,
    );
  }
  return entity => {
    if (entity === null) {
      return 'null';
    }
    const input: unknown = JSON.parse(entity);
    const output: Record<string, unknown> = {};
    for (const field of fields) {
      const parts = field.split('.');
      const path: string[] = [];
      let value: unknown = input;
      for (let index = 0; index < parts.length; index++) {
        const part = parts[index];
        if (value !== null && value !== undefined && part in Object(value)) {
          path.push(part);
          value = (value as Record<string, unknown>)[part];
        } else if (index + 1 < parts.length) {
          parts[index + 1] = `${part}.${parts[index + 1]}`;
        } else {
          value = undefined;
        }
      }
      if (value === undefined) {
        continue;
      }
      let target = output;
      for (const key of path.slice(0, -1)) {
        target[key] ??= {};
        target = target[key] as Record<string, unknown>;
      }
      target[path[path.length - 1]] = value;
    }
    return JSON.stringify(output);
  };
}

const serialise = (items: (string | null)[], project?: Projection) =>
  `[${items.map(project ?? (item => item ?? 'null')).join(',')}]`;

function decodeCursor(value: unknown): QueryCursor {
  const cursor = typeof value === 'string' ? decodeJson(value) : undefined;
  if (typeof cursor !== 'object' || cursor === null || Array.isArray(cursor)) {
    throw inputError('Malformed cursor');
  }
  const { orderFields, isPrevious, totalItems, ...rest } =
    cursor as Partial<QueryCursor>;
  if (!Array.isArray(orderFields)) {
    throw inputError('Malformed cursor');
  }
  return {
    ...rest,
    orderFields: orderFields.map(({ field, order }) => ({
      field: String(field),
      order: parseOrder(order, 'cursor'),
    })),
    isPrevious: isPrevious === true,
    totalItems: typeof totalItems === 'number' ? totalItems : undefined,
  };
}

function parseTotalItems(value: unknown): QueryEntitiesRequest['totalItems'] {
  if (value === undefined) {
    return 'include';
  }
  if (value !== 'include' && value !== 'exclude') {
    throw inputError(
      `Invalid totalItems parameter "${value}", expected one of: include, exclude`,
    );
  }
  return value;
}

async function respondToQuery(
  db: D1Database,
  request: QueryEntitiesRequest,
  fields: string[],
): Promise<Response> {
  const project = projection(fields);
  const result = await queryEntities(db, request);
  const pageInfo = {
    ...(result.prevCursor && { prevCursor: encodeJson(result.prevCursor) }),
    ...(result.nextCursor && { nextCursor: encodeJson(result.nextCursor) }),
  };
  return rawJson(
    `{"items":${serialise(result.items, project)},"totalItems":${
      result.totalItems
    },"pageInfo":${JSON.stringify(pageInfo)}}`,
  );
}

catalogRoutes.get('/entities/by-query', c => {
  const fields = splitValues(c.req.queries('fields'));
  const limit = parseCount(c.req.query('limit'), 'limit');
  const cursor = c.req.query('cursor');
  if (cursor) {
    return respondToQuery(
      c.env.DB,
      {
        cursor: decodeCursor(cursor),
        isInitial: false,
        limit,
        totalItems: 'exclude',
      },
      fields,
    );
  }
  const orderFields = (c.req.queries('orderField') ?? []).map(value => {
    const [field, order] = value.split(',');
    return { field, order: parseOrder(order, 'orderField') };
  });
  const fullTextFields = splitValues(c.req.queries('fullTextFilterFields'));
  return respondToQuery(
    c.env.DB,
    {
      cursor: {
        filter: parseFilterStrings(c.req.queries('filter') ?? []),
        orderFields,
        fullTextFilter: {
          term: c.req.query('fullTextFilterTerm') ?? '',
          fields: fullTextFields.length ? fullTextFields : undefined,
        },
        isPrevious: false,
      },
      isInitial: true,
      limit,
      offset: parseCount(c.req.query('offset'), 'offset'),
      totalItems: parseTotalItems(c.req.query('totalItems')),
    },
    fields,
  );
});

interface QueryBody {
  cursor?: unknown;
  limit?: unknown;
  offset?: unknown;
  fields?: string[];
  query?: unknown;
  orderBy?: { field?: unknown; order?: unknown }[];
  fullTextFilter?: FullTextFilter;
  totalItems?: unknown;
}

catalogRoutes.post('/entities/by-query', async c => {
  const body = await c.req.json<QueryBody>();
  const fields = body.fields ?? [];
  const limit = parseCount(body.limit, 'limit');
  if (body.cursor) {
    return respondToQuery(
      c.env.DB,
      {
        cursor: decodeCursor(body.cursor),
        isInitial: false,
        limit,
        totalItems: 'exclude',
      },
      fields,
    );
  }
  return respondToQuery(
    c.env.DB,
    {
      cursor: {
        query: body.query,
        orderFields: (body.orderBy ?? []).map(({ field, order }) => ({
          field: String(field),
          order: parseOrder(order, 'orderBy'),
        })),
        fullTextFilter: body.fullTextFilter,
        isPrevious: false,
      },
      isInitial: true,
      limit,
      offset: parseCount(body.offset, 'offset'),
      totalItems: parseTotalItems(body.totalItems),
    },
    fields,
  );
});

catalogRoutes.post('/entities/by-refs', async c => {
  const body = await c.req.json<{
    entityRefs?: unknown;
    fields?: string[];
    query?: unknown;
  }>();
  if (
    !Array.isArray(body.entityRefs) ||
    !body.entityRefs.every(ref => typeof ref === 'string')
  ) {
    throw inputError('entityRefs must be an array of strings');
  }
  const filter =
    body.query ?? parseFilterStrings(c.req.queries('filter') ?? []);
  const items = await entitiesByRefs(c.env.DB, body.entityRefs, filter);
  return rawJson(
    `{"items":${serialise(items, projection(body.fields ?? []))}}`,
  );
});

catalogRoutes.get('/entities/by-name/:kind/:namespace/:name', async c => {
  const { kind, namespace, name } = c.req.param();
  const entity = await entityByName(c.env.DB, kind, namespace, name);
  if (entity === null) {
    throw notFoundError(
      `No entity named '${name}' found, with kind '${kind}' in namespace '${namespace}'`,
    );
  }
  return rawJson(entity);
});

catalogRoutes.get(
  '/entities/by-name/:kind/:namespace/:name/ancestry',
  async c => {
    const { kind, namespace, name } = c.req.param();
    const rootRef = `${kind}:${namespace}/${name}`.toLowerCase();
    const ancestry = await entityAncestry(c.env.DB, rootRef);
    if (ancestry === null) {
      throw notFoundError(`No such entity ${rootRef}`);
    }
    return rawJson(ancestry);
  },
);

catalogRoutes.get('/entities', async c => {
  const after = c.req.query('after');
  const page = after ? decodeJson(after) : undefined;
  if (after && (typeof page !== 'object' || page === null)) {
    throw inputError('Malformed after cursor');
  }
  const paging = (page ?? {}) as { limit?: unknown; offset?: unknown };
  const limit = parseCount(paging.limit ?? c.req.query('limit'), 'limit');
  const offset = parseCount(paging.offset ?? c.req.query('offset'), 'offset');
  const order = (c.req.queries('order') ?? []).map(item => {
    const match = item.match(/^(asc|desc):(.+)$/);
    if (!match) {
      throw inputError(
        `Invalid order parameter "${item}", expected "<asc or desc>:<field name>"`,
      );
    }
    return { order: parseOrder(match[1], 'order'), field: match[2] };
  });

  const filter = parseFilterStrings(c.req.queries('filter') ?? []);
  const project = projection(splitValues(c.req.queries('fields')));

  // Without paging the Backstage backend walks its cursor query to the end:
  // entities come in order-field then id order, and any that lack the order
  // field are left out.
  if (limit === undefined && offset === undefined) {
    const items: string[] = [];
    let cursor: QueryCursor | undefined = {
      filter,
      orderFields: order,
      isPrevious: false,
    };
    for (let isInitial = true; cursor; isInitial = false) {
      const batch = await queryEntities(c.env.DB, {
        cursor,
        isInitial,
        limit: UNPAGED_BATCH_SIZE,
        totalItems: 'exclude',
      });
      items.push(...batch.items);
      cursor = batch.nextCursor;
    }
    return rawJson(serialise(items, project));
  }

  const { items, hasNextPage } = await listEntities(c.env.DB, {
    filter,
    order,
    limit,
    offset,
  });
  const headers: Record<string, string> = {};
  if (hasNextPage && limit !== undefined) {
    const url = new URL(c.req.url);
    url.searchParams.delete('offset');
    url.searchParams.set(
      'after',
      encodeJson({ limit, offset: (offset ?? 0) + limit }),
    );
    // Relative to the plugin, as the Backstage backend reports it.
    const path = url.pathname.replace(/^\/api\/[^/]+/, '');
    headers.link = `<${path}${url.search}>; rel="next"`;
  }
  return rawJson(serialise(items, project), headers);
});

function requireFacets(facets: unknown): string[] {
  const names = Array.isArray(facets)
    ? facets.filter(
        (facet): facet is string => typeof facet === 'string' && facet !== '',
      )
    : [];
  if (!names.length) {
    throw inputError('Missing facet parameter');
  }
  return names;
}

catalogRoutes.get('/entity-facets', async c =>
  c.json({
    facets: await entityFacets(
      c.env.DB,
      requireFacets(c.req.queries('facet')),
      parseFilterStrings(c.req.queries('filter') ?? []),
    ),
  }),
);

catalogRoutes.post('/entity-facets', async c => {
  const body = await c.req.json<{ facets?: unknown; query?: unknown }>();
  return c.json({
    facets: await entityFacets(
      c.env.DB,
      requireFacets(body.facets),
      body.query,
    ),
  });
});
