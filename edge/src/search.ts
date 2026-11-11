import { Hono } from 'hono';
import { callerRef, visibleTo } from './accounts';
import { inputError } from './errors';
import type { AppEnv } from './types';

/**
 * Portal search (`/api/search/query`) over the D1 full-text index. A
 * document is found, and counted, only by those who may see the entity it
 * is about.
 */
export const searchRoutes = new Hono<AppEnv>();

const PAGE_SIZE = 25;

const documentField = (name: string) =>
  `json_extract(search_documents.document, '$.${name}')`;

// The ref of the entity a document is about. Every document is about one:
// the catalog's (catalog.mjs, catalog/users.ts) name it in the last part of
// their address, /catalog/<namespace>/<kind>/<name>, and those of
// documentation pages (techdocs.mjs) in a field. A document that names none
// has no ref, and is shown to nobody.
const DOCUMENT_ENTITY_REF = `lower(${documentField(
  'kind',
)} || ':' || ${documentField(
  'namespace',
)} || '/' || CASE search_documents.type WHEN 'techdocs' THEN ${documentField(
  'name',
)} ELSE substr(${documentField(
  'location',
)}, length('/catalog/' || ${documentField(
  'namespace',
)} || '/' || ${documentField('kind')} || '/') + 1) END)`;

/**
 * Turns free text into an FTS5 query: every word must match, as a prefix.
 * Words are quoted so FTS5 operators in user input are treated as text.
 */
function matchExpression(term: string): string | undefined {
  const words = term.match(/[\p{L}\p{N}_]+/gu);
  return words?.map(word => `"${word}"*`).join(' ');
}

searchRoutes.get('/query', async c => {
  const url = new URL(c.req.url);
  const cursor = url.searchParams.get('pageCursor');
  // The cursor is the page number in base64; anything else is rejected.
  const page =
    cursor === null
      ? 0
      : Number(/^[A-Za-z0-9+/]+=*$/.test(cursor) ? atob(cursor) : NaN);
  if (!Number.isInteger(page) || page < 0) {
    throw inputError('Malformed pageCursor');
  }
  const types = [...url.searchParams]
    .filter(([key]) => key === 'types' || key.startsWith('types['))
    .map(([, value]) => value);

  const where: string[] = [];
  const params: unknown[] = [];
  const match = matchExpression(url.searchParams.get('term') ?? '');
  if (match) {
    where.push('search_documents MATCH ?');
    params.push(match);
  }
  if (types.length) {
    where.push('type IN (SELECT value FROM json_each(?))');
    params.push(JSON.stringify(types));
  }
  // filters[kind]=Component or filters[lifecycle][0]=production: every named
  // document field must equal one of its values.
  const filters = new Map<string, string[]>();
  for (const [key, value] of url.searchParams) {
    const field = key.match(/^filters\[(\w+)\](\[\d*\])?$/)?.[1];
    if (field) {
      filters.set(field, [...(filters.get(field) ?? []), value]);
    }
  }
  for (const [field, values] of filters) {
    where.push(
      "json_extract(document, '$.' || ?) IN (SELECT value FROM json_each(?))",
    );
    params.push(field, JSON.stringify(values));
  }
  const visible = visibleTo(callerRef(c));
  where.push(
    `EXISTS (SELECT 1 FROM final_entities e WHERE e.entity_ref = ${DOCUMENT_ENTITY_REF} AND (${visible.sql}))`,
  );
  params.push(...visible.params);
  const condition = `WHERE ${where.join(' AND ')}`;

  // Title matches weigh ten times a match in the description.
  const [rows, total] = await c.env.DB.batch<Record<string, unknown>>([
    c.env.DB.prepare(
      `SELECT type, document FROM search_documents ${condition} ORDER BY ${
        match ? 'bm25(search_documents, 10.0, 1.0)' : 'title'
      } LIMIT ? OFFSET ?`,
    ).bind(...params, PAGE_SIZE + 1, page * PAGE_SIZE),
    c.env.DB.prepare(
      `SELECT count(*) AS count FROM search_documents ${condition}`,
    ).bind(...params),
  ]);

  const hasNextPage = rows.results.length > PAGE_SIZE;
  const results = rows.results
    .slice(0, PAGE_SIZE)
    .map(
      (row, index) =>
        `{"type":${JSON.stringify(row.type)},"document":${
          row.document
        },"rank":${page * PAGE_SIZE + index + 1}}`,
    );
  const paging = [
    hasNextPage ? `"nextPageCursor":"${btoa(String(page + 1))}"` : '',
    page > 0 ? `"previousPageCursor":"${btoa(String(page - 1))}"` : '',
  ].filter(Boolean);
  return new Response(
    `{"results":[${results.join(',')}],${paging
      .map(p => `${p},`)
      .join('')}"numberOfResults":${Number(total.results[0]?.count ?? 0)}}`,
    { headers: { 'content-type': 'application/json; charset=utf-8' } },
  );
});
