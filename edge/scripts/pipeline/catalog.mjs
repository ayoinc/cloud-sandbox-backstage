// Reads the catalog the pipeline backend processed, straight from its SQLite
// file: the portal keeps the same tables, so rows are copied as they are.
import { createHash } from 'node:crypto';
import { join } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';
import Database from 'better-sqlite3';

const POLL_MS = 1000;
// How many polls in a row must show no change before the catalog is taken
// as settled.
const STABLE_POLLS = 5;
const SETTLE_TIMEOUT_MS = 10 * 60_000;
const PROGRESS_EVERY_MS = 10_000;
// How long a file the catalog was asked to read again is given to arrive.
const REREAD_TIMEOUT_MS = 30_000;

/** The Location entity the catalog creates for a configured location. */
const locationEntityRef = ({ type, target }) =>
  `location:default/generated-${createHash('sha1')
    .update(`${type}:${target}`)
    .digest('hex')}`;

/**
 * Opens the catalog database for reading. The backend may be writing to it
 * at the same moment, so a read waits a while for its turn before giving up.
 */
const openCatalog = dataDir =>
  new Database(join(dataDir, 'catalog.sqlite'), {
    readonly: true,
    fileMustExist: true,
    timeout: 10_000,
  });

const STATE_SQL = `
  SELECT
    (SELECT COUNT(*) FROM refresh_state) AS discovered,
    (SELECT COUNT(*) FROM refresh_state
      WHERE COALESCE(result_hash, '') = '') AS unprocessed,
    (SELECT COUNT(*) FROM stitch_queue) AS stitching,
    (SELECT COUNT(*) FROM refresh_state r
      LEFT JOIN final_entities f ON f.entity_id = r.entity_id
      WHERE r.processed_entity IS NOT NULL AND f.final_entity IS NULL) AS unstitched,
    (SELECT COUNT(*) FROM final_entities
      WHERE final_entity IS NOT NULL) AS entities,
    (SELECT COUNT(*) FROM search) AS searchRows,
    (SELECT COUNT(*) FROM relations) AS relations,
    (SELECT COUNT(*) FROM refresh_state_references) AS refs`;

/**
 * Waits until the catalog has finished processing everything it was given,
 * and returns how long that took.
 *
 * Settled means: every location in `locations` has been read, every entity
 * found so far has been processed and stitched into its final form, and none
 * of the counts has moved for several polls. The last condition covers the
 * moments in between, when one entity is done and the ones it brought in are
 * not yet recorded.
 */
export async function waitForCatalog(dataDir, locations) {
  const started = Date.now();
  const db = openCatalog(dataDir);
  try {
    const readState = db.prepare(STATE_SQL);
    const readLocationRefs = db
      .prepare(
        `SELECT entity_ref FROM refresh_state
          WHERE entity_ref LIKE 'location:default/generated-%'
            AND COALESCE(result_hash, '') <> ''`,
      )
      .pluck();
    const expected = locations.map(location => ({
      location,
      ref: locationEntityRef(location),
    }));

    let previous = '';
    let stablePolls = 0;
    let lastProgress = started;
    for (;;) {
      const state = readState.get();
      const read = new Set(readLocationRefs.all());
      const unread = expected.filter(({ ref }) => !read.has(ref));
      const done =
        unread.length === 0 &&
        state.unprocessed === 0 &&
        state.stitching === 0 &&
        state.unstitched === 0;

      const signature = JSON.stringify(state);
      stablePolls = done && signature === previous ? stablePolls + 1 : 0;
      previous = signature;
      if (stablePolls >= STABLE_POLLS) {
        return Date.now() - started;
      }

      if (Date.now() - started > SETTLE_TIMEOUT_MS) {
        const waiting = db
          .prepare(
            `SELECT entity_ref FROM refresh_state
              WHERE COALESCE(result_hash, '') = '' LIMIT 10`,
          )
          .pluck()
          .all();
        throw new Error(
          [
            `The catalog did not settle within ${
              SETTLE_TIMEOUT_MS / 60_000
            } minutes.`,
            `Found ${state.discovered} entities: ${state.unprocessed} not processed, ${state.stitching} queued for stitching, ${state.unstitched} without a final form.`,
            unread.length &&
              `Locations not read (${unread.length}): ${unread
                .slice(0, 10)
                .map(({ location }) => location.target)
                .join(', ')}`,
            waiting.length && `Waiting for: ${waiting.join(', ')}`,
          ]
            .filter(Boolean)
            .join('\n'),
        );
      }
      if (Date.now() - lastProgress >= PROGRESS_EVERY_MS) {
        lastProgress = Date.now();
        console.log(
          `  catalog: ${state.entities} of ${state.discovered} entities ready, ${unread.length} locations still to read`,
        );
      }
      await sleep(POLL_MS);
    }
  } finally {
    db.close();
  }
}

/**
 * Waits until none of the entities has a processing error any more, or until
 * it is clear the errors are staying. Call it after asking the catalog to
 * refresh them; `waitForCatalog` then covers whatever they bring in.
 */
export async function waitForReread(dataDir, entityRefs) {
  const db = openCatalog(dataDir);
  try {
    const stillFailing = db
      .prepare(
        `SELECT COUNT(*) FROM refresh_state
          WHERE errors IS NOT NULL AND errors NOT IN ('', '[]')
            AND entity_ref IN (SELECT value FROM json_each(?))`,
      )
      .pluck();
    const deadline = Date.now() + REREAD_TIMEOUT_MS;
    while (
      stillFailing.get(JSON.stringify(entityRefs)) > 0 &&
      Date.now() < deadline
    ) {
      await sleep(POLL_MS);
    }
  } finally {
    db.close();
  }
}

/**
 * The processing errors the catalog recorded, split by where the failing
 * entity came from. `registered` holds those that descend from one of the
 * given locations; `configured` holds all others.
 */
export function readProcessingErrors(dataDir, registeredLocations) {
  const db = openCatalog(dataDir);
  try {
    const failed = db
      .prepare(
        `SELECT entity_ref, errors FROM refresh_state
          WHERE errors IS NOT NULL AND errors NOT IN ('', '[]')
          ORDER BY entity_ref`,
      )
      .all();
    if (failed.length === 0) {
      return { configured: [], registered: [] };
    }

    const parents = new Map();
    const references = db
      .prepare(
        `SELECT source_entity_ref, target_entity_ref FROM refresh_state_references
          WHERE source_entity_ref IS NOT NULL`,
      )
      .all();
    for (const {
      source_entity_ref: parent,
      target_entity_ref: child,
    } of references) {
      parents.set(child, [...(parents.get(child) ?? []), parent]);
    }
    const registeredRoots = new Set(registeredLocations.map(locationEntityRef));
    const fromRegistered = entityRef => {
      const seen = new Set();
      const queue = [entityRef];
      while (queue.length > 0) {
        const ref = queue.pop();
        if (registeredRoots.has(ref)) {
          return true;
        }
        if (!seen.has(ref)) {
          seen.add(ref);
          queue.push(...(parents.get(ref) ?? []));
        }
      }
      return false;
    };

    const result = { configured: [], registered: [] };
    for (const { entity_ref: entityRef, errors } of failed) {
      const messages = JSON.parse(errors).map(
        error => `${error.name}: ${error.message}`,
      );
      result[fromRegistered(entityRef) ? 'registered' : 'configured'].push({
        entityRef,
        messages,
      });
    }
    return result;
  } finally {
    db.close();
  }
}

/** The search document Backstage's catalog collator builds for an entity. */
function catalogDocument(entity) {
  const namespace = entity.metadata.namespace || 'default';
  const type = entity.spec?.type?.toString() || 'other';
  return {
    title: entity.metadata.title ?? entity.metadata.name,
    text: entity.metadata.description ?? '',
    location: `/catalog/${encodeURIComponent(namespace)}/${encodeURIComponent(
      entity.kind,
    ).toLowerCase()}/${encodeURIComponent(entity.metadata.name)}`,
    componentType: type,
    type,
    namespace,
    kind: entity.kind,
    lifecycle: entity.spec?.lifecycle || '',
    owner: entity.spec?.owner || '',
  };
}

/**
 * Reads the finished catalog in one transaction, so the three tables agree
 * with each other even if the backend is still running. Rows are arrays in
 * the column order of the portal's pipeline contract; `entities` are the
 * parsed entities, in the order of `finalEntities`.
 */
export function readCatalog(dataDir) {
  const db = openCatalog(dataDir);
  try {
    const rows = sql => db.prepare(sql).raw().all();
    const [finalEntities, search, references] = db.transaction(() => [
      rows(
        `SELECT entity_id, entity_ref, final_entity FROM final_entities
          WHERE final_entity IS NOT NULL ORDER BY entity_ref`,
      ),
      rows(
        `SELECT s.entity_id, s.key, s.value, s.original_value FROM search s
          JOIN final_entities e ON e.entity_id = s.entity_id
          WHERE e.final_entity IS NOT NULL ORDER BY s.entity_id, s.key, s.value`,
      ),
      rows(
        `SELECT source_entity_ref, target_entity_ref FROM refresh_state_references
          WHERE source_entity_ref IS NOT NULL
          ORDER BY target_entity_ref, source_entity_ref`,
      ),
    ])();
    const entities = finalEntities.map(row => JSON.parse(row[2]));
    const documents = entities.map(entity => {
      const document = catalogDocument(entity);
      return [
        document.title,
        document.text,
        'software-catalog',
        JSON.stringify(document),
      ];
    });
    return { finalEntities, search, references, entities, documents };
  } finally {
    db.close();
  }
}
