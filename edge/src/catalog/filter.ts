import { inputError } from '../errors';
import { isRecord } from '../json';

/** A SQL fragment with its bound parameters. All user input goes in `params`. */
export interface SqlFragment {
  sql: string;
  params: unknown[];
}

type Primitive = string | number | boolean;

const isPrimitive = (value: unknown): value is Primitive =>
  typeof value === 'string' ||
  typeof value === 'number' ||
  typeof value === 'boolean';

/** `EXISTS` over the search rows of the entity aliased `e`. */
const searchExists = (condition: string) =>
  `EXISTS (SELECT 1 FROM search s WHERE s.entity_id = e.entity_id AND ${condition})`;

/** Membership test against a JSON array bound as one parameter. */
export const inJsonArray = (column: string) =>
  `${column} IN (SELECT value FROM json_each(?))`;

const join = (parts: SqlFragment[], operator: 'AND' | 'OR'): SqlFragment => ({
  sql: parts.map(part => `(${part.sql})`).join(` ${operator} `),
  params: parts.flatMap(part => part.params),
});

/**
 * Translates a Backstage catalog filter predicate into SQL over `search`,
 * for a query whose entity table is aliased `e`.
 *
 * Port of `applyPredicateEntityFilterToQuery` in
 * `@backstage/plugin-catalog-backend`; keep the two in step when upgrading.
 */
export function predicateToSql(filter: unknown): SqlFragment {
  if (!isRecord(filter)) {
    throw inputError(
      `Invalid filter predicate: top-level primitive values are not supported. Wrap the value in a field expression, e.g. { "kind": ${JSON.stringify(
        filter,
      )} }`,
    );
  }
  if ('$not' in filter) {
    const inner = predicateToSql(filter.$not);
    return { sql: `NOT (${inner.sql})`, params: inner.params };
  }
  if ('$all' in filter) {
    const parts = asArray(filter.$all, '$all');
    return parts.length
      ? join(parts.map(predicateToSql), 'AND')
      : { sql: '1 = 1', params: [] };
  }
  if ('$any' in filter) {
    const parts = asArray(filter.$any, '$any');
    return parts.length
      ? join(parts.map(predicateToSql), 'OR')
      : { sql: '1 = 0', params: [] };
  }
  const fields = Object.entries(filter);
  if (!fields.length) {
    return { sql: '1 = 1', params: [] };
  }
  return join(
    fields.map(([key, value]) => fieldCondition(key.toLowerCase(), value)),
    'AND',
  );
}

function asArray(value: unknown, operator: string): unknown[] {
  if (!Array.isArray(value)) {
    throw inputError(`Invalid filter predicate: ${operator} must be an array`);
  }
  return value;
}

function fieldCondition(key: string, value: unknown): SqlFragment {
  if (isPrimitive(value)) {
    return {
      sql: searchExists('s.key = ? AND s.value = ?'),
      params: [key, String(value).toLowerCase()],
    };
  }
  if (isRecord(value)) {
    if ('$exists' in value) {
      const exists = searchExists('s.key = ?');
      return { sql: value.$exists ? exists : `NOT ${exists}`, params: [key] };
    }
    if ('$in' in value) {
      const values = asArray(value.$in, '$in').map(v =>
        String(v).toLowerCase(),
      );
      return {
        sql: searchExists(`s.key = ? AND ${inJsonArray('s.value')}`),
        params: [key, JSON.stringify(values)],
      };
    }
    if ('$hasPrefix' in value) {
      const prefix = String(value.$hasPrefix).toLowerCase();
      // substr() rather than LIKE: D1 caps LIKE patterns at 50 bytes.
      return {
        sql: searchExists('s.key = ? AND substr(s.value, 1, length(?)) = ?'),
        params: [key, prefix, prefix],
      };
    }
    if ('$contains' in value) {
      const target = value.$contains;
      if (isPrimitive(target)) {
        return {
          sql: searchExists('s.key = ? AND s.value = ?'),
          params: [key, String(target).toLowerCase()],
        };
      }
      if (isRecord(target)) {
        if (key === 'relations') {
          return relationCondition(target);
        }
        throw inputError(
          `Object form of $contains is not supported for field "${key}"`,
        );
      }
      throw inputError(
        `Unsupported $contains target for field "${key}": ${JSON.stringify(
          target,
        )}`,
      );
    }
  }
  throw inputError(
    `Invalid filter predicate value for field "${key}": expected a primitive value, $exists, $in, $hasPrefix, or $contains operator, but got ${JSON.stringify(
      value,
    )}`,
  );
}

function relationCondition(target: Record<string, unknown>): SqlFragment {
  let type: string | undefined;
  let targetRefs: string[] | undefined;
  for (const [rawKey, value] of Object.entries(target)) {
    const key = rawKey.toLowerCase();
    if (key === 'type' && type === undefined) {
      if (typeof value !== 'string') {
        throw inputError(
          'The $contains operator for "relations" requires a "type" string property',
        );
      }
      type = value;
    } else if (key === 'targetref' && targetRefs === undefined) {
      targetRefs = relationTargets(value);
    } else if (key === 'type' || key === 'targetref') {
      throw inputError(
        `Duplicate key "${rawKey}" in $contains for "relations"`,
      );
    } else {
      throw inputError(
        `Unsupported key "${rawKey}" in $contains for "relations". Only "type" and "targetRef" are supported`,
      );
    }
  }
  if (!type) {
    throw inputError(
      'The $contains operator for "relations" requires a "type" string property',
    );
  }
  const key = `relations.${type.toLowerCase()}`;
  return targetRefs
    ? {
        sql: searchExists(`s.key = ? AND ${inJsonArray('s.value')}`),
        params: [key, JSON.stringify(targetRefs)],
      }
    : { sql: searchExists('s.key = ?'), params: [key] };
}

function relationTargets(value: unknown): string[] {
  if (typeof value === 'string') {
    return [value.toLowerCase()];
  }
  if (
    isRecord(value) &&
    Object.keys(value).length === 1 &&
    Array.isArray(value.$in) &&
    value.$in.every(v => typeof v === 'string')
  ) {
    if (!value.$in.length) {
      throw inputError(
        'Empty "$in" array for $contains on "relations" is not allowed',
      );
    }
    return value.$in.map(v => v.toLowerCase());
  }
  throw inputError(
    `Unsupported value in $contains for "relations": expected a string or { "$in": [strings] }, but got ${JSON.stringify(
      value,
    )}`,
  );
}

/**
 * Parses `filter=a=b,c=d` query strings: statements in one string are AND-ed,
 * separate strings are OR-ed, and a bare key tests that the field exists.
 */
export function parseFilterStrings(filters: string[]): unknown {
  const alternatives = filters
    .map(parseFilterString)
    .filter(parts => parts.length > 0)
    .map(parts => (parts.length === 1 ? parts[0] : { $all: parts }));
  if (!alternatives.length) {
    return undefined;
  }
  return alternatives.length === 1 ? alternatives[0] : { $any: alternatives };
}

function parseFilterString(filter: string): Record<string, unknown>[] {
  const byKey = new Map<string, string[] | undefined>();
  for (const statement of filter.split(',').map(s => s.trim())) {
    if (!statement) {
      continue;
    }
    const equals = statement.indexOf('=');
    const key = (equals === -1 ? statement : statement.slice(0, equals)).trim();
    if (!key) {
      throw inputError(
        `Invalid filter, '${statement}' is not a valid statement (expected a string on the form a=b or a= or a)`,
      );
    }
    if (!byKey.has(key)) {
      byKey.set(key, undefined);
    }
    if (equals !== -1) {
      byKey.set(key, [
        ...(byKey.get(key) ?? []),
        statement.slice(equals + 1).trim(),
      ]);
    }
  }
  return Array.from(byKey, ([key, values]) => {
    if (!values) {
      return { [key]: { $exists: true } };
    }
    return { [key]: values.length === 1 ? values[0] : { $in: values } };
  });
}
