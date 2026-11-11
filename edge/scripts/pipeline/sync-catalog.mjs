// Rebuilds what the portal serves: the catalog, its search index, the
// documentation sites and the list of template actions.
//
// The portal is a Cloudflare Worker and cannot process a catalog or build
// documentation itself. This script starts the pipeline backend (a real
// Backstage catalog and scaffolder), waits for it to process every entity
// file, builds the documentation with mkdocs, and pushes all of it to the
// portal's /api/pipeline endpoints. The portal swaps the new catalog in with
// one commit, so readers never see half of it. For the deployed portal those
// endpoints are served by a Worker started on this machine: see bridge.mjs.
//
//   yarn workspace @internal/edge catalog:sync
//
// Settings come from the environment: see settings.mjs.
import { appendFile } from 'node:fs/promises';
import {
  backendLogTail,
  backendRequest,
  prepareDataDir,
  readBackendLog,
  startBackend,
  writeRunConfig,
} from './backend.mjs';
import { connectPortal } from './bridge.mjs';
import {
  readCatalog,
  readProcessingErrors,
  waitForCatalog,
  waitForReread,
} from './catalog.mjs';
import { portalRequest } from './portal.mjs';
import { dataDirFor, readSettings } from './settings.mjs';
import {
  assertDocsToolchain,
  buildDocs,
  deleteStaleDocs,
  uploadDocs,
} from './techdocs.mjs';

// Limits of POST /api/pipeline/catalog/rows. The byte limit leaves room for
// the few fields sent around the rows.
const MAX_ROWS_PER_REQUEST = 500;
const MAX_ROW_BYTES_PER_REQUEST = 399_000;
const PUSH_ATTEMPTS = 3;
const REREAD_ATTEMPTS = 2;

const seconds = ms => `${(ms / 1000).toFixed(1)} s`;

/** The request bodies that carry `rows` of one table, each within the limits. */
function* rowRequests(syncId, table, rows) {
  const open = `{"syncId":${JSON.stringify(
    syncId,
  )},"table":"${table}","rows":[`;
  let batch = [];
  let bytes = 0;
  for (const row of rows) {
    const json = JSON.stringify(row);
    const size = Buffer.byteLength(json) + 1;
    if (size > MAX_ROW_BYTES_PER_REQUEST) {
      throw new Error(
        `A row of ${table} is ${Math.ceil(
          size / 1024,
        )} KB, more than one request to the portal may carry: ${json.slice(
          0,
          200,
        )}`,
      );
    }
    if (
      batch.length === MAX_ROWS_PER_REQUEST ||
      bytes + size > MAX_ROW_BYTES_PER_REQUEST
    ) {
      yield `${open}${batch.join(',')}]}`;
      batch = [];
      bytes = 0;
    }
    batch.push(json);
    bytes += size;
  }
  if (batch.length > 0) {
    yield `${open}${batch.join(',')}]}`;
  }
}

/**
 * Stages every table with the portal and commits them together. Row requests
 * are not safe to repeat one by one, so after a failure that may be passing
 * the whole push starts again with a new sync, which clears the staging.
 */
async function pushCatalog(portal, tables) {
  for (let attempt = 1; ; attempt++) {
    try {
      const { syncId } = await portalRequest(
        portal,
        'POST',
        '/api/pipeline/catalog/begin',
      );
      for (const [table, rows] of Object.entries(tables)) {
        for (const body of rowRequests(syncId, table, rows)) {
          await portalRequest(portal, 'POST', '/api/pipeline/catalog/rows', {
            body,
            contentType: 'application/json',
          });
        }
      }
      return await portalRequest(
        portal,
        'POST',
        '/api/pipeline/catalog/commit',
        { json: { syncId } },
      );
    } catch (error) {
      const passing = !error.status || error.status >= 500;
      if (!passing || attempt === PUSH_ATTEMPTS) {
        throw error;
      }
      console.warn(`  ${error.message}\n  Starting the push again.`);
    }
  }
}

/** Entity refs that two files claim; the catalog keeps the first it read. */
function entityConflicts(backendLog) {
  return [
    ...new Set(
      [
        ...backendLog.matchAll(
          /Detected conflicting entityRef (\S+) already referenced by (\S+) and now also (\S+)/g,
        ),
      ].map(
        ([, entityRef, kept, ignored]) =>
          `${entityRef} is defined in ${kept} and again in ${ignored}`,
      ),
    ),
  ];
}

const listErrors = failures =>
  failures
    .map(
      ({ entityRef, messages }) =>
        `  ${entityRef}\n${messages.map(m => `    ${m}`).join('\n')}`,
    )
    .join('\n');

async function sync(portal, { github, githubToken }, dataDir) {
  const started = Date.now();
  // In GitHub Actions these lines become annotations on the run.
  const warn = message =>
    console.warn(github ? `::warning::${message}` : `Warning: ${message}`);

  console.log(`Syncing the catalog to ${portal.name}`);
  const { items: registered } = await portalRequest(
    portal,
    'GET',
    '/api/pipeline/locations',
    { retry: true },
  );

  await prepareDataDir(dataDir);
  const locations = await writeRunConfig(dataDir, { github, registered });
  console.log(
    `Reading ${locations.length} locations (${registered.length} registered with the portal)` +
      (github
        ? ` from ${github.repository} at ${github.refName}`
        : ' from this checkout'),
  );
  const backend = await startBackend({ dataDir, githubToken });
  let settleMs;
  let actions;
  let templatingExtensions;
  let catalog;
  let errors;
  try {
    settleMs = await waitForCatalog(dataDir, locations);
    // Every file is fetched over the network, and now and then a connection
    // drops. Ask for what failed again before calling the catalog broken. A
    // file that is not there is not going to appear.
    for (let attempt = 1; attempt <= REREAD_ATTEMPTS; attempt++) {
      const { configured, registered: fromRegistered } = readProcessingErrors(
        dataDir,
        registered,
      );
      const failed = [...configured, ...fromRegistered]
        .filter(
          ({ messages }) => !messages.some(m => m.startsWith('NotFoundError')),
        )
        .map(({ entityRef }) => entityRef);
      if (failed.length === 0) {
        break;
      }
      console.log(
        `Reading ${failed.length} entities again after an error (attempt ${attempt} of ${REREAD_ATTEMPTS})`,
      );
      for (const entityRef of failed) {
        await backendRequest(backend, '/api/catalog/refresh', {
          method: 'POST',
          json: { entityRef },
        });
      }
      await waitForReread(dataDir, failed);
      settleMs += await waitForCatalog(dataDir, locations);
    }
    actions = await backendRequest(backend, '/api/scaffolder/v2/actions');
    templatingExtensions = await backendRequest(
      backend,
      '/api/scaffolder/v2/templating-extensions',
    );
    catalog = readCatalog(dataDir);
    errors = readProcessingErrors(dataDir, registered);
  } catch (error) {
    console.error(
      `Last output of the pipeline backend:\n${backendLogTail(dataDir)}`,
    );
    throw error;
  } finally {
    await backend.stop();
  }
  console.log(
    `Catalog settled in ${seconds(settleMs)}: ${
      catalog.finalEntities.length
    } entities, ${catalog.search.length} search rows`,
  );

  for (const conflict of entityConflicts(readBackendLog(dataDir))) {
    warn(`Conflicting entity: ${conflict}. Only the first is in the catalog.`);
  }
  if (errors.registered.length > 0) {
    warn(
      `${errors.registered.length} entities of registered locations failed and are left out`,
    );
    console.warn(listErrors(errors.registered));
  }
  if (errors.configured.length > 0) {
    throw new Error(
      `${
        errors.configured.length
      } entities of the configured locations failed to process. Nothing was sent to the portal.\n${listErrors(
        errors.configured,
      )}`,
    );
  }

  const docsStarted = Date.now();
  const docs = await buildDocs({
    entities: catalog.finalEntities.map(([, entityRef], index) => ({
      entityRef,
      entity: catalog.entities[index],
    })),
    dataDir,
    github,
    githubToken,
  });
  const builtSites = docs.sites.filter(site => site.outputDir);
  const failedSites = docs.sites.filter(site => site.error);
  console.log(
    `Documentation built in ${seconds(Date.now() - docsStarted)}: ${
      builtSites.length
    } sites, ${failedSites.length} failed`,
  );
  if (docs.unresolved.length > 0) {
    warn(
      `${docs.unresolved.length} entities have a documentation reference that cannot be followed`,
    );
    for (const { entityRef, error } of docs.unresolved) {
      console.warn(`  ${entityRef}: ${error}`);
    }
  }
  if (failedSites.length > 0) {
    warn(`${failedSites.length} documentation sites did not build`);
    for (const site of failedSites) {
      console.warn(`  ${site.source}: ${site.error}`);
    }
  }

  const uploadStarted = Date.now();
  const upload = await uploadDocs(portal, docs.sites);
  console.log(
    `Documentation uploaded in ${seconds(Date.now() - uploadStarted)}: ${
      upload.uploaded
    } of ${upload.files} files changed (${(
      upload.uploadedBytes /
      1024 /
      1024
    ).toFixed(1)} MB)`,
  );

  const techdocsDocuments = builtSites.flatMap(site => site.documents);
  const tables = {
    final_entities: catalog.finalEntities,
    search: catalog.search,
    refresh_state_references: catalog.references,
    search_documents: [...catalog.documents, ...techdocsDocuments],
    // A site that failed to build this time keeps serving its last upload.
    techdocs_sites: docs.sites
      .filter(site => site.outputDir || upload.keptSiteIds.has(site.siteId))
      .flatMap(site =>
        site.entities.map(({ entityRef }) => [entityRef, site.siteId]),
      ),
  };
  const pushStarted = Date.now();
  const committed = await pushCatalog(portal, tables);
  // Only now is nothing live pointing at the documentation that went away.
  await deleteStaleDocs(portal, upload.staleKeys);
  await portalRequest(portal, 'PUT', '/api/pipeline/scaffolder/actions', {
    json: actions,
    retry: true,
  });
  await portalRequest(
    portal,
    'PUT',
    '/api/pipeline/scaffolder/templating-extensions',
    { json: templatingExtensions, retry: true },
  );
  console.log(`Catalog pushed in ${seconds(Date.now() - pushStarted)}`);

  const sent = {
    entities: tables.final_entities.length,
    searchRows: tables.search.length,
    documents: tables.search_documents.length,
    sites: tables.techdocs_sites.length,
  };
  for (const [name, count] of Object.entries(sent)) {
    if (committed[name] !== count) {
      throw new Error(
        `The portal committed ${committed[name]} ${name} but ${count} were sent.`,
      );
    }
  }

  const summary = [
    ['Entities', sent.entities],
    ['Catalog search rows', sent.searchRows],
    ['Entity ancestry links', tables.refresh_state_references.length],
    [
      'Search documents',
      `${sent.documents} (${catalog.documents.length} catalog, ${techdocsDocuments.length} documentation)`,
    ],
    ['Entities with documentation', sent.sites],
    [
      'Documentation sites',
      `${builtSites.length} built, ${failedSites.length} failed`,
    ],
    [
      'Documentation files',
      `${upload.uploaded} uploaded, ${upload.unchanged} unchanged, ${upload.staleKeys.length} deleted`,
    ],
    ['Template actions', actions.length],
    ['Locations', `${locations.length} (${registered.length} registered)`],
    ['Catalog settled in', seconds(settleMs)],
    ['Total time', seconds(Date.now() - started)],
  ];
  console.log(
    `\nSynced to ${portal.name}\n${summary
      .map(([label, value]) => `  ${label}: ${value}`)
      .join('\n')}`,
  );
  if (process.env.GITHUB_STEP_SUMMARY) {
    await appendFile(
      process.env.GITHUB_STEP_SUMMARY,
      [
        '## Portal sync',
        '',
        '| | |',
        '| --- | --- |',
        ...summary.map(([label, value]) => `| ${label} | ${value} |`),
        ...(failedSites.length > 0
          ? [
              '',
              '### Documentation that did not build',
              '',
              ...failedSites.map(
                site => `- \`${site.source}\`: ${site.error.split('\n')[0]}`,
              ),
            ]
          : []),
        '',
      ].join('\n'),
    );
  }
}

async function main() {
  const settings = readSettings();
  const dataDir = dataDirFor('pipeline');
  await assertDocsToolchain();
  const portal = await connectPortal(settings, dataDir);
  try {
    await sync(portal, settings, dataDir);
  } finally {
    await portal.stop();
  }
}

// Leave through process.exit so the handlers that stop the backend and the
// portal Worker run.
process.once('SIGINT', () => process.exit(130));
process.once('SIGTERM', () => process.exit(143));

try {
  await main();
} catch (error) {
  console.error(`\nSync failed: ${error.message}`);
  process.exit(1);
}
