// Checks that the Worker shows every caller their own account's catalog and
// nobody else's: entities, counts, facets, ancestry, registered files,
// search results, documentation, CI data, ownership lists and templates, and
// that what is hidden answers exactly as what does not exist.
//
// It puts into the Worker's local database two people without an
// organisation, two organisations, a registered file and its entities for
// each of them, a file nobody has claimed, a shared entity, the people as
// signed-in users, search documents and documentation sites; asks every
// route as each of them; and takes it all out again. Then it unregisters
// files, has one registered again by another account, and asks every route
// again each time.
//
// What a catalog sync does with an unregistered file is checked only on a
// database whose catalog holds nothing else, such as a new one made with
// `--persist-to`: a sync replaces the whole catalog.
//
// Run it against a Worker started with
// `yarn dev --var PORTAL_REPO:-none-/none`, and it refuses one started
// otherwise. Registering and removing a file starts a catalog sync, and
// running a template starts its workflow, in the repository PORTAL_REPO
// names. No account on GitHub has a name that begins with a hyphen, so
// there is no such repository to start one in, also when the check finds a
// fault: the Worker asks GitHub, and is told so. With its token when it has
// one, it also asks GitHub for the runs of repositories that do not exist,
// and for REGISTER_FILE.
//
// The rows go in through `wrangler d1 execute --local`, which writes to the
// same local database, and the callers' tokens are signed here, so it
// refuses any Worker that is not on this machine. Do not run it against a
// local Worker bound to the deployed database (wrangler.pipeline.jsonc).
//
//   EDGE_URL        (default http://localhost:8787) the Worker
//   SESSION_SECRET  (default: the one in .dev.vars) signs the callers' tokens
//   PIPELINE_TOKEN  (default: the one in .dev.vars) what the pipeline presents
//   PERSIST_TO      where the Worker keeps its local data, when it was
//                   started with `--persist-to`
//   REGISTER_FILE   a catalog file on github.com the Worker's token can
//                   read, as https://github.com/<owner>/<repo>/blob/<branch>/
//                   <path>.yaml, that is not registered in this database.
//                   With it, registering a file is checked too: whose it
//                   becomes, and who is told it is registered. Set it only
//                   for a Worker started as above: a registration that
//                   succeeds starts a sync where PORTAL_REPO names one.
import { execFileSync } from 'node:child_process';
import {
  createHash,
  createHmac,
  randomBytes,
  randomInt,
  randomUUID,
} from 'node:crypto';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isDeepStrictEqual } from 'node:util';

const EDGE = process.env.EDGE_URL ?? 'http://localhost:8787';
if (!['localhost', '127.0.0.1', '[::1]'].includes(new URL(EDGE).hostname)) {
  console.error(
    `${EDGE} is not on this machine. This check writes to the database of the Worker it calls.`,
  );
  process.exit(1);
}
// As in wrangler.jsonc and the package's db:migrate scripts.
const DATABASE = 'cloud-sandbox';
const EDGE_DIR = fileURLToPath(new URL('..', import.meta.url));

const read = path => readFileSync(new URL(path, import.meta.url), 'utf8');

const setting = name =>
  process.env[name] ??
  new RegExp(`^${name}=(.*)$`, 'm')
    .exec(read('../.dev.vars'))?.[1]
    .replace(/^"|"$/g, '');
const secret = setting('SESSION_SECRET');
const pipelineToken = setting('PIPELINE_TOKEN');
if (!secret || !pipelineToken) {
  console.error(
    'Set SESSION_SECRET and PIPELINE_TOKEN, or add them to edge/.dev.vars.',
  );
  process.exit(1);
}

// wrangler as this package has it, run with the node that runs this.
const require = createRequire(import.meta.url);
const wranglerPackage = require.resolve('wrangler/package.json');
const WRANGLER = join(
  dirname(wranglerPackage),
  JSON.parse(readFileSync(wranglerPackage, 'utf8')).bin.wrangler,
);

/** Runs wrangler on the local database: never `--remote`. */
function wrangler(args) {
  try {
    return execFileSync(
      process.execPath,
      [
        WRANGLER,
        'd1',
        'execute',
        DATABASE,
        '--local',
        '--yes',
        ...(process.env.PERSIST_TO
          ? ['--persist-to', process.env.PERSIST_TO]
          : []),
        ...args,
      ],
      { cwd: EDGE_DIR, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
    );
  } catch (error) {
    throw new Error(
      `wrangler d1 execute failed:\n${error.stdout ?? ''}${error.stderr ?? ''}`,
    );
  }
}

/** Runs statements on the Worker's local database. */
function execute(sql) {
  const dir = mkdtempSync(join(tmpdir(), 'check-privacy-'));
  try {
    const file = join(dir, 'statements.sql');
    writeFileSync(file, sql);
    wrangler(['--file', file]);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

/** The rows one SELECT finds in the Worker's local database. */
const select = sql =>
  JSON.parse(wrangler(['--json', '--command', sql]))[0].results;

/** A user token as the Worker issues them at sign-in (edge/src/auth.ts). */
function tokenFor(userEntityRef) {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = [
    { typ: 'vnd.backstage.user', alg: 'HS256' },
    {
      iss: `${EDGE}/api/auth`,
      sub: userEntityRef,
      ent: [userEntityRef],
      aud: 'backstage',
      iat: now,
      exp: now + 600,
    },
  ]
    .map(part => Buffer.from(JSON.stringify(part)).toString('base64url'))
    .join('.');
  const signature = createHmac('sha256', secret)
    .update(unsigned)
    .digest('base64url');
  return `${unsigned}.${signature}`;
}

// Everything this run puts in carries these letters, so it is told from
// what the database already holds and is found again to be removed.
const run = Array.from({ length: 6 }, () =>
  String.fromCharCode(97 + randomInt(26)),
).join('');
// A word of its own in every search document of this run.
const WORD = `zq${run}`;
// The spec.type of every component of this run: lists, totals and facets
// are narrowed to it.
const TYPE = `privacy-${run}`;
const ABSENT = `absent-${run}`;

const PEOPLE = ['alice', 'bob', 'carol', 'dave', 'erin'];
const ADMINS = ['alice', 'carol'];
const ORGANISATIONS = {
  north: { id: randomBytes(16).toString('hex'), members: ['carol', 'dave'] },
  south: { id: randomBytes(16).toString('hex'), members: ['erin'] },
};
const userName = person => `${person}-${run}`;
const userRef = person => `user:default/${userName(person)}`;
const slug = organisation => `privacy-${organisation}-${run}`;

// Whose each registered file is. `unclaimed` is nobody's.
const ACCOUNTS = {
  alice: userRef('alice'),
  bob: userRef('bob'),
  north: `organisation:${ORGANISATIONS.north.id}`,
  south: `organisation:${ORGANISATIONS.south.id}`,
  unclaimed: null,
};
const OWNERS = Object.keys(ACCOUNTS);
// The accounts each person sees.
const SEES = {
  alice: [ACCOUNTS.alice],
  bob: [ACCOUNTS.bob],
  carol: [ACCOUNTS.north],
  dave: [ACCOUNTS.north],
  erin: [ACCOUNTS.south],
};
const PEOPLE_SEEN_BY = {
  alice: ['alice'],
  bob: ['bob'],
  carol: ['carol', 'dave'],
  dave: ['carol', 'dave'],
  erin: ['erin'],
};

const TARGETS = {
  alice: `https://github.com/privacy-check-${run}/alice/blob/main/catalog-info.yaml`,
  bob: `https://github.com/privacy-check-${run}/bob/blob/main/catalog-info.yaml`,
  // In capitals, as GitHub may show an address: the catalog's search values
  // are in lower case.
  north: `https://github.com/Privacy-Check-${run}/North/blob/main/catalog-info.yaml`,
  // Longer than the 200 characters the catalog keeps of a search value.
  south: `https://github.com/privacy-check-${run}/south/blob/main/${'deep/'.repeat(
    40,
  )}catalog-info.yaml`,
  unclaimed: `https://github.com/privacy-check-${run}/unclaimed/blob/main/catalog-info.yaml`,
};
const SHARED_ORIGIN = `file:/app/catalog/privacy-check-${run}.yaml`;
const originOf = owner =>
  owner === 'shared' ? SHARED_ORIGIN : `url:${TARGETS[owner]}`;
const locationId = target =>
  createHash('sha1').update(`url:${target}`).digest('hex');
const locationRef = target =>
  `location:default/generated-${locationId(target)}`;

// What the database should hold as the check goes on. `shownTo` is the
// account each file's entities are shown to: none while the file is
// unclaimed or was unregistered. `registrations` is the files that are
// registered, each with its account, and `addresses` every address a file
// of this run was ever registered at.
const shownTo = { ...ACCOUNTS };
const registrations = new Map(
  OWNERS.map(owner => [TARGETS[owner], ACCOUNTS[owner]]),
);
const addresses = new Set(registrations.keys());
// The files that were unregistered and still have their row, each with the
// account it had.
const unregistered = new Map();
// What template runs register as the check goes on: Dave's run, a run the
// portal knows nothing of, and one whose task it does not know.
const MADE = {
  dave: `https://github.com/privacy-check-${run}/made-by-dave/tree/main/catalog-info.yaml`,
  nobody: `https://github.com/privacy-check-${run}/made-by-nobody/tree/main/catalog-info.yaml`,
  unknown: `https://github.com/privacy-check-${run}/made-by-unknown/tree/main/catalog-info.yaml`,
};
// An address spelled another way: the letter before the file's extension
// as its percent code. It is the same file.
const respelled = target =>
  target.replace(
    /(.)(\.ya?ml)$/,
    (_, letter, extension) =>
      `%${letter.charCodeAt(0).toString(16)}${extension}`,
  );
// Which of the files each person's accounts cover. Everyone also sees what
// is shared.
const filesOf = person =>
  OWNERS.filter(owner => SEES[person].includes(shownTo[owner]));
// The files a person is shown as registered: those of their accounts and,
// for a portal administrator, those nobody has claimed.
const listedTo = person =>
  [...registrations]
    .filter(([, account]) =>
      account === null
        ? ADMINS.includes(person)
        : SEES[person].includes(account),
    )
    .map(([target]) => target)
    .sort();

const componentName = owner => `${owner}-${run}`;
const componentRef = owner => `component:default/${componentName(owner)}`;
const COMPONENTS = ['shared', ...OWNERS];
const ABSENT_COMPONENT = `component:default/${ABSENT}`;
const NORTH_TEAM = `north-team-${run}`;
const SHARED_TEAM = `shared-team-${run}`;
const NORTH_TEMPLATE = `north-template-${run}`;
// A template everyone sees that makes a team in the operator's GitHub
// organisation, and is kept in the repository the portal runs in.
const ORGANISATION_TEMPLATE = `organisation-template-${run}`;
// What the Worker is to be started with as PORTAL_REPO: see the top.
const PORTAL_REPOSITORY = '-none-/none';
// The repository each component is in: for a registered file, the one its
// file is in.
const repositoryOf = owner =>
  owner === 'shared'
    ? `privacy-check-${run}/shared`
    : /github\.com\/([^/]+\/[^/]+)\//.exec(TARGETS[owner])[1];
// The components that have documentation.
const DOCUMENTED = ['shared', 'alice', 'north'];
const siteId = owner => `privacy-${run}-${owner}`;

const sorted = values => [...values].sort();
const componentsSeenBy = person => sorted(['shared', ...filesOf(person)]);

function entity(kind, name, origin, spec, annotations = {}, relations = []) {
  const id = randomUUID();
  return {
    id,
    ref: `${kind}:default/${name}`.toLowerCase(),
    origin,
    value: {
      apiVersion:
        kind === 'Template'
          ? 'scaffolder.backstage.io/v1beta3'
          : 'backstage.io/v1alpha1',
      kind,
      metadata: {
        namespace: 'default',
        name,
        uid: id,
        annotations: {
          'backstage.io/managed-by-location': origin,
          'backstage.io/managed-by-origin-location': origin,
          ...annotations,
        },
      },
      spec,
      relations,
    },
  };
}

// Every component is owned by the shared team, which so points at them all.
const components = COMPONENTS.map(owner =>
  entity(
    'Component',
    componentName(owner),
    originOf(owner),
    { type: TYPE, lifecycle: 'production', owner: NORTH_TEAM },
    {
      'github.com/project-slug': repositoryOf(owner),
      'backstage.io/techdocs-ref': `url:https://github.com/privacy-check-${run}/${owner}/tree/main`,
    },
    [{ type: 'ownedBy', targetRef: `group:default/${SHARED_TEAM}` }],
  ),
);
const locationEntities = OWNERS.map(owner =>
  entity(
    'Location',
    `generated-${locationId(TARGETS[owner])}`,
    originOf(owner),
    { type: 'url', target: TARGETS[owner] },
  ),
);
const users = PEOPLE.map(person =>
  entity('User', userName(person), 'sign-in:github', {
    profile: { displayName: person },
    memberOf: [],
  }),
);
const others = [
  entity('Group', NORTH_TEAM, originOf('north'), {
    type: 'team',
    children: [],
  }),
  entity(
    'Group',
    SHARED_TEAM,
    SHARED_ORIGIN,
    { type: 'team', children: [] },
    {},
    // The last is an entity that does not exist.
    [...COMPONENTS.map(componentRef), ABSENT_COMPONENT].map(targetRef => ({
      type: 'ownerOf',
      targetRef,
    })),
  ),
  entity('Template', NORTH_TEMPLATE, originOf('north'), {
    type: 'service',
    parameters: [{ title: `Fill in ${run}`, properties: {} }],
    steps: [],
  }),
  entity(
    'Template',
    ORGANISATION_TEMPLATE,
    SHARED_ORIGIN,
    {
      type: 'service',
      parameters: [],
      steps: [{ id: 'team', action: 'github:team:create' }],
    },
    { 'github.com/project-slug': PORTAL_REPOSITORY },
  ),
  // From Bob's file, and naming Alice's repository as its own.
  entity(
    'Template',
    `deputy-${run}`,
    originOf('bob'),
    { type: 'service', parameters: [], steps: [] },
    { 'github.com/project-slug': repositoryOf('alice') },
  ),
];
const entities = [...components, ...locationEntities, ...users, ...others];

/** The rows the catalog keeps for filtering, as `buildEntitySearch` makes them. */
function searchRows({ id, value }) {
  const annotations = Object.entries(value.metadata.annotations).map(
    ([name, text]) => [`metadata.annotations.${name}`, text],
  );
  return [
    ['kind', value.kind],
    ['metadata.name', value.metadata.name],
    ['metadata.namespace', 'default'],
    ['metadata.uid', id],
    ['spec.type', value.spec.type ?? null],
    ['spec.owner', value.spec.owner ?? null],
    ...annotations,
    ...value.relations.map(({ type, targetRef }) => [
      `relations.${type.toLowerCase()}`,
      targetRef,
    ]),
  ]
    .filter(([, text]) => text !== null)
    .map(([key, text]) =>
      text.length > 200
        ? [id, key, null, null]
        : [id, key, text.toLowerCase(), text],
    );
}

const catalogDocument = ({ value }, title) => ({
  title,
  text: '',
  location: `/catalog/default/${value.kind.toLowerCase()}/${
    value.metadata.name
  }`,
  componentType: value.spec.type ?? 'other',
  type: value.spec.type ?? 'other',
  namespace: 'default',
  kind: value.kind,
  lifecycle: '',
  owner: '',
});
const documentTitle = owner => `${WORD} component ${owner}`;
const pageTitle = owner => `${WORD} page ${owner}`;
const personTitle = person => `${WORD} person ${person}`;
const documents = [
  ...COMPONENTS.map((owner, index) => [
    'software-catalog',
    catalogDocument(components[index], documentTitle(owner)),
  ]),
  ...PEOPLE.map((person, index) => [
    'software-catalog',
    catalogDocument(users[index], personTitle(person)),
  ]),
  ...DOCUMENTED.map(owner => [
    'techdocs',
    {
      title: pageTitle(owner),
      text: '',
      location: `/docs/default/component/${componentName(owner)}/`,
      path: '',
      kind: 'component',
      namespace: 'default',
      name: componentName(owner),
    },
  ]),
  // About no entity at all: nothing says who may read it, so nobody does.
  ['software-catalog', { title: `${WORD} nothing`, text: '', location: '/' }],
];

const quote = value =>
  value === null ? 'NULL' : `'${String(value).replaceAll("'", "''")}'`;
const insert = (table, columns, rows) =>
  `INSERT INTO ${table} (${columns.join(', ')}) VALUES\n${rows
    .map(row => `(${row.map(quote).join(', ')})`)
    .join(',\n')};\n`;

const now = new Date().toISOString();
const taskId = randomUUID();
// A task of Alice's that waits to be run, as the portal stores one.
const openTaskId = randomUUID();
const OPEN_TASK = {
  templateRef: `template:default/${NORTH_TEMPLATE}`,
  values: { name: `made-${run}`, nested: { list: [1, 'two'] } },
  createdBy: userRef('alice'),
};
// Which entity came of which.
const REFERENCES = [
  ...OWNERS.map(owner => [locationRef(TARGETS[owner]), componentRef(owner)]),
  // Not how a catalog comes to be, but it gives an entity everyone sees a
  // parent only Bob does.
  [locationRef(TARGETS.bob), componentRef('shared')],
];
const SEED = [
  insert(
    'organisations',
    ['slug', 'name', 'id', 'name_key'],
    Object.entries(ORGANISATIONS).map(([name, { id }]) => [
      slug(name),
      `Privacy ${name} ${run}`,
      id,
      `privacy ${name} ${run}`,
    ]),
  ),
  insert(
    'organisation_members',
    ['user_ref', 'slug', 'role', 'added_at', 'added_by'],
    Object.entries(ORGANISATIONS).flatMap(([name, { members }]) =>
      members.map((person, index) => [
        userRef(person),
        slug(name),
        index ? 'member' : 'owner',
        now,
        userRef(members[0]),
      ]),
    ),
  ),
  insert(
    'branding_admins',
    ['entity_ref', 'type', 'added_by'],
    ADMINS.map(person => [userRef(person), 'user', 'check-privacy']),
  ),
  insert(
    'locations',
    ['type', 'target', 'account'],
    OWNERS.map(owner => ['url', TARGETS[owner], ACCOUNTS[owner]]),
  ),
  insert(
    'final_entities',
    ['entity_id', 'entity_ref', 'final_entity'],
    entities.map(({ id, ref, value }) => [id, ref, JSON.stringify(value)]),
  ),
  insert(
    'search',
    ['entity_id', 'key', 'value', 'original_value'],
    entities.flatMap(searchRows),
  ),
  insert(
    'refresh_state_references',
    ['source_entity_ref', 'target_entity_ref'],
    REFERENCES,
  ),
  insert(
    'signed_in_users',
    [
      'entity_ref',
      'entity_id',
      'final_entity',
      'search_rows',
      'search_document',
      'updated_at',
    ],
    users.map((user, index) => [
      user.ref,
      user.id,
      JSON.stringify(user.value),
      JSON.stringify(searchRows(user).map(([, ...row]) => row)),
      JSON.stringify(catalogDocument(user, personTitle(PEOPLE[index]))),
      now,
    ]),
  ),
  insert(
    'search_documents',
    ['title', 'text', 'type', 'document'],
    documents.map(([type, document]) => [
      document.title,
      document.text,
      type,
      JSON.stringify(document),
    ]),
  ),
  insert(
    'techdocs_sites',
    ['entity_ref', 'site_id'],
    DOCUMENTED.map(owner => [componentRef(owner), siteId(owner)]),
  ),
  // A template run of Dave's that has ended, for what the pipeline
  // registers, and one of Alice's that has not begun.
  insert(
    'tasks',
    ['id', 'spec', 'status', 'created_by', 'created_at'],
    [
      [taskId, '{}', 'completed', userRef('dave'), now],
      [
        openTaskId,
        JSON.stringify({
          steps: [],
          parameters: OPEN_TASK.values,
          user: { ref: OPEN_TASK.createdBy },
          templateInfo: { entityRef: OPEN_TASK.templateRef },
        }),
        'open',
        OPEN_TASK.createdBy,
        now,
      ],
    ],
  ),
].join('');

const inList = values => `(${values.map(quote).join(', ')})`;
const CLEANUP = [
  `DELETE FROM search WHERE entity_id IN ${inList(entities.map(e => e.id))};`,
  `DELETE FROM final_entities WHERE entity_id IN ${inList(
    entities.map(e => e.id),
  )};`,
  `DELETE FROM refresh_state_references WHERE target_entity_ref IN ${inList(
    COMPONENTS.map(componentRef),
  )};`,
  `DELETE FROM signed_in_users WHERE entity_ref IN ${inList(
    PEOPLE.map(userRef),
  )};`,
  `DELETE FROM search_documents WHERE instr(title, ${quote(WORD)}) > 0;`,
  `DELETE FROM techdocs_sites WHERE site_id IN ${inList(
    DOCUMENTED.map(siteId),
  )};`,
  `DELETE FROM locations WHERE instr(lower(target), ${quote(
    `privacy-check-${run}`,
  )}) > 0;`,
  `DELETE FROM ownership_overrides WHERE entity_ref IN ${inList(
    COMPONENTS.map(componentRef),
  )};`,
  `DELETE FROM tasks WHERE created_by IN ${inList(PEOPLE.map(userRef))};`,
  `DELETE FROM branding_admins WHERE entity_ref IN ${inList(
    PEOPLE.map(userRef),
  )};`,
  `DELETE FROM organisation_members WHERE slug IN ${inList(
    Object.keys(ORGANISATIONS).map(slug),
  )};`,
  `DELETE FROM organisations WHERE slug IN ${inList(
    Object.keys(ORGANISATIONS).map(slug),
  )};`,
].join('\n');

const siteObjects = DOCUMENTED.flatMap(owner => [
  [`sites/${siteId(owner)}/index.html`, 'text/html', `<h1>${owner}</h1>`],
  [
    `sites/${siteId(owner)}/techdocs_metadata.json`,
    'application/json',
    JSON.stringify({ site_name: owner }),
  ],
]);

/** One request to the Worker, as a person, the pipeline or nobody. */
async function ask(who, method, path, { json, headers, scheme } = {}) {
  let authorization;
  if (who === 'pipeline') {
    authorization = `Bearer ${pipelineToken}`;
  } else if (who) {
    authorization = `${scheme ?? 'Bearer'} ${tokenFor(userRef(who))}`;
  }
  const response = await fetch(`${EDGE}${path}`, {
    method,
    headers: {
      ...(authorization && { authorization }),
      ...(json !== undefined && { 'content-type': 'application/json' }),
      ...headers,
    },
    body: json === undefined ? undefined : JSON.stringify(json),
    redirect: 'manual',
  });
  const text = await response.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = undefined;
  }
  return { status: response.status, text, body, headers: response.headers };
}

let checks = 0;
let problems = [];

function expect(what, seen, wanted) {
  checks += 1;
  if (!isDeepStrictEqual(seen, wanted)) {
    problems.push(
      `${what}\n    answered ${JSON.stringify(seen)?.slice(
        0,
        600,
      )}\n    expected ${JSON.stringify(wanted)}`,
    );
  }
}

/**
 * Expects two answers to be one and the same refusal: `hidden`, about a
 * thing the caller may not see, and `missing`, about one that does not
 * exist. They may differ only in the name that was asked for.
 */
function expectAsMissing(what, hidden, missing, [hiddenName, missingName]) {
  const shape = (answer, name) => ({
    status: answer.status,
    type: answer.headers.get('content-type'),
    text: answer.text.toLowerCase().replaceAll(name.toLowerCase(), '<name>'),
  });
  expect(
    `${what}: answers as for a thing that is not there`,
    shape(hidden, hiddenName),
    shape(missing, missingName),
  );
  expect(`${what}: is not found`, hidden.status, 404);
}

const namesOf = items => sorted(items.map(item => item.metadata.name));
const ofThisRun = names => sorted(names.filter(name => name.includes(run)));
const COMPONENT_FILTER = `filter=${encodeURIComponent(
  `kind=component,spec.type=${TYPE}`,
)}`;

/** Follows a cursor-paged entity query to its end. */
async function walk(first, next) {
  const names = [];
  const totals = [];
  for (let page = await first(); ; ) {
    if (page.status !== 200) {
      return { names, totals, failed: page.text };
    }
    names.push(...page.body.items.map(item => item.metadata.name));
    totals.push(page.body.totalItems);
    const cursor = page.body.pageInfo.nextCursor;
    if (!cursor) {
      return { names, totals };
    }
    page = await next(cursor);
  }
}

const sections = {
  'catalog: lists, totals and cursors': async person => {
    const seen = componentsSeenBy(person).map(componentName);
    const list = await ask(
      person,
      'GET',
      `/api/catalog/entities?${COMPONENT_FILTER}`,
    );
    expect('GET /entities', namesOf(list.body), seen);
    const paged = await ask(
      person,
      'GET',
      `/api/catalog/entities?${COMPONENT_FILTER}&limit=50&order=asc:metadata.name`,
    );
    expect('GET /entities, paged', namesOf(paged.body), seen);

    const byGet = await walk(
      () =>
        ask(
          person,
          'GET',
          `/api/catalog/entities/by-query?${COMPONENT_FILTER}&limit=1&orderField=metadata.name,asc`,
        ),
      cursor =>
        ask(
          person,
          'GET',
          `/api/catalog/entities/by-query?limit=1&cursor=${encodeURIComponent(
            cursor,
          )}`,
        ),
    );
    expect('GET /entities/by-query, every page', byGet, {
      names: seen,
      totals: seen.map(() => seen.length),
    });
    const byPost = await walk(
      () =>
        ask(person, 'POST', '/api/catalog/entities/by-query', {
          json: { query: { kind: 'component', 'spec.type': TYPE }, limit: 1 },
        }),
      cursor =>
        ask(person, 'POST', '/api/catalog/entities/by-query', {
          json: { cursor, limit: 1 },
        }),
    );
    expect(
      'POST /entities/by-query, every page',
      { ...byPost, names: sorted(byPost.names) },
      { names: seen, totals: seen.map(() => seen.length) },
    );
    const byText = await ask(
      person,
      'GET',
      `/api/catalog/entities/by-query?filter=kind=component&fullTextFilterTerm=${run}&fullTextFilterFields=metadata.name`,
    );
    expect(
      'GET /entities/by-query, by text',
      { names: namesOf(byText.body.items), total: byText.body.totalItems },
      { names: seen, total: seen.length },
    );
  },

  'catalog: by refs, by name and ancestry': async person => {
    const mine = componentsSeenBy(person);
    const refs = [
      ...COMPONENTS.map(componentRef),
      `component:default/${ABSENT}`,
    ];
    const byRefs = await ask(person, 'POST', '/api/catalog/entities/by-refs', {
      json: { entityRefs: refs },
    });
    expect(
      'POST /entities/by-refs',
      byRefs.body.items.map(item => item?.metadata.name ?? null),
      [...COMPONENTS, ABSENT].map(owner =>
        mine.includes(owner) ? componentName(owner) : null,
      ),
    );
    for (const path of ['', '/ancestry']) {
      const missing = await ask(
        person,
        'GET',
        `/api/catalog/entities/by-name/component/default/${ABSENT}${path}`,
      );
      for (const owner of COMPONENTS) {
        const answer = await ask(
          person,
          'GET',
          `/api/catalog/entities/by-name/component/default/${componentName(
            owner,
          )}${path}`,
        );
        const what = `GET /entities/by-name${path} of ${owner}'s`;
        if (mine.includes(owner)) {
          expect(what, answer.status, 200);
        } else {
          expectAsMissing(what, answer, missing, [
            componentName(owner),
            ABSENT,
          ]);
        }
      }
    }
    // Everyone sees the shared entity. Only Bob sees the file it was given
    // as a parent.
    const ancestry = await ask(
      person,
      'GET',
      `/api/catalog/entities/by-name/component/default/${componentName(
        'shared',
      )}/ancestry`,
    );
    const parents = person === 'bob' ? [locationRef(TARGETS.bob)] : [];
    expect(
      'ancestry of the shared entity',
      ancestry.body.items.map(item => [
        item.entity.metadata.name,
        item.parentEntityRefs,
      ]),
      [
        [componentName('shared'), parents],
        ...parents.map(() => [`generated-${locationId(TARGETS.bob)}`, []]),
      ],
    );
  },

  'catalog: facets': async person => {
    const seen = componentsSeenBy(person).map(componentName);
    const counts = await ask(
      person,
      'GET',
      '/api/catalog/entity-facets?facet=spec.type&filter=kind=component',
    );
    expect(
      'GET /entity-facets, count',
      counts.body.facets['spec.type'].filter(({ value }) => value === TYPE),
      [{ value: TYPE, count: seen.length }],
    );
    const names = await ask(person, 'POST', '/api/catalog/entity-facets', {
      json: { facets: ['metadata.name'], query: { 'spec.type': TYPE } },
    });
    expect(
      'POST /entity-facets, values',
      names.body.facets['metadata.name'],
      seen.map(value => ({ value, count: 1 })),
    );
  },

  'catalog: people': async person => {
    const list = await ask(
      person,
      'GET',
      '/api/catalog/entities?filter=kind=user',
    );
    expect(
      'GET /entities of kind user',
      ofThisRun(list.body.map(item => item.metadata.name)),
      sorted(PEOPLE_SEEN_BY[person].map(userName)),
    );
    const missing = await ask(
      person,
      'GET',
      `/api/catalog/entities/by-name/user/default/${ABSENT}`,
    );
    for (const other of PEOPLE) {
      const answer = await ask(
        person,
        'GET',
        `/api/catalog/entities/by-name/user/default/${userName(other)}`,
      );
      const what = `GET /entities/by-name of user ${other}`;
      if (PEOPLE_SEEN_BY[person].includes(other)) {
        expect(what, answer.status, 200);
      } else {
        expectAsMissing(what, answer, missing, [userName(other), ABSENT]);
      }
    }
  },

  'catalog: registered files': async person => {
    const mine = listedTo(person);
    const list = await ask(person, 'GET', '/api/catalog/locations');
    expect(
      'GET /locations',
      sorted(
        list.body
          .map(({ data }) => data.target)
          .filter(target => target.toLowerCase().includes(run)),
      ),
      mine,
    );
    const absent = locationId(
      `https://github.com/${ABSENT}/x/blob/main/a.yaml`,
    );
    const missing = {
      id: await ask(person, 'GET', `/api/catalog/locations/${absent}`),
      entity: await ask(
        person,
        'GET',
        `/api/catalog/locations/by-entity/location/default/generated-${absent}`,
      ),
      // Only a portal administrator is let as far as looking for the file.
      removal:
        ADMINS.includes(person) &&
        (await ask(person, 'DELETE', `/api/catalog/locations/${absent}`)),
    };
    // Also the addresses of files that were unregistered since.
    for (const target of addresses) {
      const id = locationId(target);
      const what = target.replace(/^https:\/\/github.com\/[^/]+\//, '');
      const byId = await ask(person, 'GET', `/api/catalog/locations/${id}`);
      const byEntity = await ask(
        person,
        'GET',
        `/api/catalog/locations/by-entity/location/default/generated-${id}`,
      );
      if (mine.includes(target)) {
        expect(`GET /locations/:id of ${what}`, byId.body?.target, target);
        expect(
          `GET /locations/by-entity of ${what}`,
          byEntity.body?.target,
          target,
        );
        continue;
      }
      expectAsMissing(`GET /locations/:id of ${what}`, byId, missing.id, [
        id,
        absent,
      ]);
      expectAsMissing(
        `GET /locations/by-entity of ${what}`,
        byEntity,
        missing.entity,
        [id, absent],
      );
      // An administrator of the portal, not of other accounts' files. Not
      // asked when the file is shown, which is reported above: asking to
      // remove it would remove it.
      if (missing.removal && byId.status === 404) {
        expectAsMissing(
          `DELETE /locations/:id of ${what}`,
          await ask(person, 'DELETE', `/api/catalog/locations/${id}`),
          missing.removal,
          [id, absent],
        );
      }
    }
  },

  search: async person => {
    const titles = sorted([
      ...componentsSeenBy(person).map(documentTitle),
      ...componentsSeenBy(person)
        .filter(owner => DOCUMENTED.includes(owner))
        .map(pageTitle),
      ...PEOPLE_SEEN_BY[person].map(personTitle),
    ]);
    const found = await ask(person, 'GET', `/api/search/query?term=${WORD}`);
    expect(
      'GET /search/query',
      {
        titles: sorted(
          found.body.results.map(({ document }) => document.title),
        ),
        numberOfResults: found.body.numberOfResults,
      },
      { titles, numberOfResults: titles.length },
    );
    const pages = await ask(
      person,
      'GET',
      `/api/search/query?term=${WORD}&types[0]=techdocs`,
    );
    const pageTitles = titles.filter(title => title.includes(' page '));
    expect(
      'GET /search/query, documentation only',
      {
        titles: sorted(
          pages.body.results.map(({ document }) => document.title),
        ),
        numberOfResults: pages.body.numberOfResults,
      },
      { titles: pageTitles, numberOfResults: pageTitles.length },
    );
  },

  documentation: async person => {
    const mine = componentsSeenBy(person);
    const cookie = (
      await ask(person, 'GET', '/api/techdocs/.backstage/auth/v1/cookie')
    ).headers
      .getSetCookie()
      .map(value => value.split(';')[0])
      .join('; ');
    const routes = {
      'static file': name => [
        person,
        'GET',
        `/api/techdocs/static/docs/default/component/${name}/index.html`,
      ],
      'static file, by cookie': name => [
        undefined,
        'GET',
        `/api/techdocs/static/docs/default/component/${name}/index.html`,
        { headers: { cookie } },
      ],
      'site metadata': name => [
        person,
        'GET',
        `/api/techdocs/metadata/techdocs/default/component/${name}`,
      ],
      'entity metadata': name => [
        person,
        'GET',
        `/api/techdocs/metadata/entity/default/component/${name}`,
      ],
      sync: name => [
        person,
        'GET',
        `/api/techdocs/sync/default/component/${name}`,
      ],
    };
    for (const [route, request] of Object.entries(routes)) {
      const missing = await ask(...request(ABSENT));
      // Entity metadata and sync need no site; the others do.
      const owners = ['entity metadata', 'sync'].includes(route)
        ? COMPONENTS
        : DOCUMENTED;
      for (const owner of owners) {
        const answer = await ask(...request(componentName(owner)));
        const what = `documentation ${route} of ${owner}'s`;
        if (mine.includes(owner)) {
          expect(what, answer.status, 200);
        } else {
          expectAsMissing(what, answer, missing, [
            componentName(owner),
            ABSENT,
          ]);
        }
      }
    }
  },

  // The shared team is the owner of every component, and so points at
  // them all: at those of other accounts too, which are not to be named.
  'catalog: relations': async person => {
    const owned = sorted([
      ...componentsSeenBy(person).map(componentRef),
      ABSENT_COMPONENT,
    ]);
    const ownerOf = found =>
      sorted(
        (found?.relations ?? [])
          .filter(relation => relation.type === 'ownerOf')
          .map(relation => relation.targetRef),
      );
    const team = `kind=group,metadata.name=${SHARED_TEAM}`;
    const byName = `/api/catalog/entities/by-name/group/default/${SHARED_TEAM}`;
    const served = {
      'GET /entities/by-name': (await ask(person, 'GET', byName)).body,
      'GET /entities/by-name/ancestry': (
        await ask(person, 'GET', `${byName}/ancestry`)
      ).body?.items?.[0]?.entity,
      'POST /entities/by-refs': (
        await ask(person, 'POST', '/api/catalog/entities/by-refs', {
          json: { entityRefs: [`group:default/${SHARED_TEAM}`] },
        })
      ).body?.items?.[0],
      'GET /entities': (
        await ask(person, 'GET', `/api/catalog/entities?filter=${team}`)
      ).body?.[0],
      'GET /entities, paged': (
        await ask(
          person,
          'GET',
          `/api/catalog/entities?filter=${team}&limit=5&order=asc:metadata.name`,
        )
      ).body?.[0],
      'GET /entities/by-query': (
        await ask(
          person,
          'GET',
          `/api/catalog/entities/by-query?filter=${team}`,
        )
      ).body?.items?.[0],
      'POST /entities/by-query': (
        await ask(person, 'POST', '/api/catalog/entities/by-query', {
          json: { query: { kind: 'group', 'metadata.name': SHARED_TEAM } },
        })
      ).body?.items?.[0],
    };
    for (const [route, found] of Object.entries(served)) {
      expect(
        `${route}: the relations of the shared team`,
        ownerOf(found),
        owned,
      );
    }

    const facets = await ask(
      person,
      'GET',
      `/api/catalog/entity-facets?facet=relations.ownerOf&filter=${team}`,
    );
    expect(
      'GET /entity-facets of a relation',
      facets.body.facets['relations.ownerOf'],
      owned.map(value => ({ value, count: 1 })),
    );
    // Sorted by a relation, an entity comes once for each of its values.
    const ordered = await ask(
      person,
      'GET',
      `/api/catalog/entities/by-query?filter=${team}&orderField=relations.ownerof,asc`,
    );
    expect(
      'GET /entities/by-query ordered by a relation',
      ordered.body.items.length,
      owned.length,
    );

    // Asking whether the team owns a component says whether there is one.
    for (const ref of [...COMPONENTS.map(componentRef), ABSENT_COMPONENT]) {
      const found = owned.includes(ref) ? 1 : 0;
      const name = ref.split('/')[1];
      const totals = {
        filter: await ask(
          person,
          'GET',
          `/api/catalog/entities/by-query?filter=${encodeURIComponent(
            `kind=group,relations.ownerof=${ref}`,
          )}`,
        ),
        $contains: await ask(person, 'POST', '/api/catalog/entities/by-query', {
          json: {
            query: {
              kind: 'group',
              relations: { $contains: { type: 'ownerOf', targetRef: ref } },
            },
          },
        }),
        'full text': await ask(
          person,
          'GET',
          `/api/catalog/entities/by-query?filter=kind=group&fullTextFilterTerm=${name}&fullTextFilterFields=relations.ownerof`,
        ),
      };
      for (const [how, answer] of Object.entries(totals)) {
        expect(
          `groups that own ${name}, by ${how}`,
          [answer.body?.totalItems, answer.body?.items?.length],
          [found, found],
        );
      }
    }
  },

  'CI data': async person => {
    const mine = componentsSeenBy(person);
    const runsOf = repository =>
      ask(person, 'GET', `/api/github/repos/${repository}/actions/runs`, {
        scheme: 'token',
      });
    // Passed on: what comes back is GitHub's answer, or that the Worker has
    // no token for GitHub. Either way not the Worker's refusal.
    const passedOn = answer =>
      !answer.text.includes('No entity in the catalog belongs to');
    const absent = `privacy-check-${run}/${ABSENT}`;
    const missing = await runsOf(absent);
    // Bob has an entity of his own that names Alice's repository: that
    // does not make it his to read.
    for (const owner of COMPONENTS) {
      const repository = repositoryOf(owner).toLowerCase();
      const answer = await runsOf(repository);
      const what = `GET /github runs of ${owner}'s repository`;
      if (mine.includes(owner)) {
        expect(`${what}: is passed on`, passedOn(answer), true);
      } else {
        expectAsMissing(what, answer, missing, [repository, absent]);
      }
    }
    // The repository the portal runs in, which a template everyone sees is
    // kept in, holds the logs of everyone's template runs.
    const portal = PORTAL_REPOSITORY.toUpperCase();
    const answer = await runsOf(portal);
    const what = 'GET /github runs of the repository the portal runs in';
    if (ADMINS.includes(person)) {
      expect(`${what}: is passed on`, passedOn(answer), true);
    } else {
      expectAsMissing(what, answer, missing, [portal, absent]);
    }
  },

  templates: async person => {
    const schema = name =>
      ask(
        person,
        'GET',
        `/api/scaffolder/v2/templates/default/template/${name}/parameter-schema`,
      );
    const start = name =>
      ask(person, 'POST', '/api/scaffolder/v2/tasks', {
        json: {
          templateRef: `template:default/${name}`,
          values: { name: `made-${run}` },
        },
      });
    const answer = await schema(NORTH_TEMPLATE);
    if (filesOf(person).includes('north')) {
      // Running it would start a workflow in GitHub: not from a check.
      expect('template parameter schema', answer.body?.title, NORTH_TEMPLATE);
    } else {
      expectAsMissing(
        'template parameter schema',
        answer,
        await schema(ABSENT),
        [NORTH_TEMPLATE, ABSENT],
      );
      // If the template is not hidden, starting it would run it for real.
      if (answer.status === 404) {
        expectAsMissing(
          'POST /scaffolder/v2/tasks',
          await start(NORTH_TEMPLATE),
          await start(ABSENT),
          [NORTH_TEMPLATE, ABSENT],
        );
      }
    }

    // A template whose steps change the operator's GitHub organisation is
    // a portal administrator's to run. For anyone else nothing is stored.
    const started = await start(ORGANISATION_TEMPLATE);
    const stored = select(
      `SELECT status, json_extract(spec, '$.parameters.name') AS name, json_extract(spec, '$.user.entity.metadata.name') AS user FROM tasks WHERE created_by = ${quote(
        userRef(person),
      )} AND json_extract(spec, '$.templateInfo.entityRef') = ${quote(
        `template:default/${ORGANISATION_TEMPLATE}`,
      )} AND id = ${quote(started.body?.id ?? '')}`,
    );
    if (ADMINS.includes(person)) {
      // As far as the workflow, which there is no repository to start in:
      // the task is stored, with what was filled in and who by, and ended.
      expect(
        'POST /scaffolder/v2/tasks of a template for administrators',
        [started.status, stored],
        [
          201,
          [{ status: 'failed', name: `made-${run}`, user: userName(person) }],
        ],
      );
    } else {
      expect(
        'POST /scaffolder/v2/tasks of a template for administrators',
        [started.status, started.body?.error, stored],
        [
          403,
          {
            name: 'NotAllowedError',
            message: 'Only a portal administrator can run this template',
          },
          [],
        ],
      );
      expect(
        'nothing is stored for someone who may not run it',
        select(
          `SELECT count(*) AS tasks FROM tasks WHERE created_by = ${quote(
            userRef(person),
          )} AND json_extract(spec, '$.templateInfo.entityRef') = ${quote(
            `template:default/${ORGANISATION_TEMPLATE}`,
          )}`,
        ),
        [{ tasks: 0 }],
      );
    }
  },

  ownership: async person => {
    const routes = ['entities', 'orphans', 'groups', 'overrides'];
    if (!ADMINS.includes(person)) {
      for (const route of routes) {
        const answer = await ask(
          person,
          'GET',
          `/api/ownership-management/${route}`,
        );
        expect(
          `GET /ownership-management/${route}, not an administrator`,
          [answer.status, answer.body],
          [403, { error: 'Admin access required' }],
        );
      }
      const reassign = await ask(
        person,
        'POST',
        '/api/ownership-management/reassign',
        {
          json: { entityRef: componentRef('shared'), newOwner: SHARED_TEAM },
        },
      );
      expect('POST /reassign, not an administrator', reassign.status, 403);
      const remove = await ask(
        person,
        'DELETE',
        `/api/ownership-management/overrides?entityRef=${componentRef(
          'shared',
        )}`,
      );
      expect('DELETE /overrides, not an administrator', remove.status, 403);
      return;
    }
    const mine = componentsSeenBy(person);
    const seesNorth = mine.includes('north');
    const read = async route =>
      (await ask(person, 'GET', `/api/ownership-management/${route}`)).body;
    const listed = (await read('entities')).entities.filter(item =>
      item.name.includes(run),
    );
    expect(
      'GET /ownership-management/entities',
      listed.map(item => [item.name, item.ownerExists]),
      mine.map(owner => [componentName(owner), seesNorth]),
    );
    // Every component names the north team as its owner. To those who do
    // not see that group, it is an owner that does not exist.
    expect(
      'GET /ownership-management/orphans',
      ofThisRun((await read('orphans')).orphans.map(item => item.name)),
      seesNorth ? [] : mine.map(componentName),
    );
    expect(
      'GET /ownership-management/groups',
      ofThisRun((await read('groups')).groups.map(item => item.name)),
      sorted([SHARED_TEAM, ...(seesNorth ? [NORTH_TEAM] : [])]),
    );

    const reassign = (entityRef, newOwner) =>
      ask(person, 'POST', '/api/ownership-management/reassign', {
        json: { entityRef, newOwner },
      });
    const missingEntity = await reassign(
      `component:default/${ABSENT}`,
      SHARED_TEAM,
    );
    const missingGroup = await reassign(componentRef('shared'), ABSENT);
    for (const owner of COMPONENTS.filter(one => !mine.includes(one))) {
      expectAsMissing(
        `POST /reassign of ${owner}'s`,
        await reassign(componentRef(owner), SHARED_TEAM),
        missingEntity,
        [componentName(owner), ABSENT],
      );
    }
    if (!seesNorth) {
      const answer = await reassign(componentRef('shared'), NORTH_TEAM);
      expect(
        'POST /reassign to a group of another account',
        [answer.status, answer.text.replaceAll(NORTH_TEAM, ABSENT)],
        [400, missingGroup.text],
      );
    }
  },
};

/** Expects the `locations` rows of this run to be what the check made of them. */
function expectRows(what) {
  const byTarget = ([one], [other]) => (one < other ? -1 : 1);
  expect(
    what,
    select(
      `SELECT target, account, removed_at IS NOT NULL AS removed FROM locations WHERE instr(lower(target), ${quote(
        `privacy-check-${run}`,
      )}) > 0`,
    )
      .map(({ target, account, removed }) => [target, account, removed])
      .sort(byTarget),
    [
      ...[...registrations].map(row => [...row, 0]),
      ...[...unregistered].map(row => [...row, 1]),
    ].sort(byTarget),
  );
}

/** Expects the pipeline to be given the registered files of this run to read. */
async function expectPipelineFiles(what) {
  const list = await ask('pipeline', 'GET', '/api/pipeline/locations');
  expect(
    what,
    sorted(
      list.body.items
        .map(item => item.target)
        .filter(target => target.toLowerCase().includes(run)),
    ),
    sorted(registrations.keys()),
  );
}

/** What takes more than one caller: an override, and what the pipeline registers. */
async function together() {
  // Carol, an administrator in the north organisation, gives its component
  // another owner. Alice is an administrator too, and sees none of it.
  const overrides = async person =>
    (
      await ask(person, 'GET', '/api/ownership-management/overrides')
    ).body.overrides
      .map(item => item.entityRef)
      .filter(ref => ref.includes(run));
  const remove = (person, ref) =>
    ask(
      person,
      'DELETE',
      `/api/ownership-management/overrides?entityRef=${ref}`,
    );
  const reassigned = await ask(
    'carol',
    'POST',
    '/api/ownership-management/reassign',
    {
      json: { entityRef: componentRef('north'), newOwner: SHARED_TEAM },
    },
  );
  expect('POST /reassign of her own', reassigned.status, 200);
  expect('GET /overrides, hers', await overrides('carol'), [
    componentRef('north'),
  ]);
  expect('GET /overrides, another account', await overrides('alice'), []);
  expectAsMissing(
    "DELETE /overrides of another account's",
    await remove('alice', componentRef('north')),
    await remove('alice', `component:default/${ABSENT}`),
    [componentName('north'), ABSENT],
  );
  expect(
    'DELETE /overrides of her own',
    (await remove('carol', componentRef('north'))).status,
    200,
  );

  // What a template run registers goes to the account of whoever started
  // the run: Dave, so the north organisation. It is stored in one spelling,
  // however the run spells it.
  // Alice's file again, in other letters and spelled with a percent code,
  // by Dave's run: it is the same file, and stays hers.
  for (const json of [
    { type: 'url', target: respelled(MADE.dave), taskId },
    { type: 'url', target: MADE.nobody },
    { type: 'url', target: MADE.unknown, taskId: randomUUID() },
    {
      type: 'url',
      target: TARGETS.alice.replace('/alice/', '/ALICE/'),
      taskId,
    },
    { type: 'url', target: respelled(TARGETS.alice), taskId },
    { type: 'url', target: TARGETS.alice.replace('/blob/', '/tree/'), taskId },
  ]) {
    const answer = await ask('pipeline', 'POST', '/api/pipeline/locations', {
      json,
    });
    expect(`POST /pipeline/locations ${json.target}`, answer.status, 200);
  }
  registrations.set(MADE.dave, ACCOUNTS.north);
  registrations.set(MADE.nobody, null);
  registrations.set(MADE.unknown, null);
  Object.values(MADE).forEach(target => addresses.add(target));
  expectRows('what a template run registers is filed under who started it');
  await expectPipelineFiles('GET /pipeline/locations lists every file');
  for (const person of PEOPLE) {
    const list = await ask(person, 'GET', '/api/catalog/locations');
    expect(
      `GET /locations as ${person}, after the pipeline`,
      sorted(
        list.body
          .map(({ data }) => data.target)
          .filter(target => target.toLowerCase().includes(run)),
      ),
      listedTo(person),
    );
  }

  // A run asks the portal what its task is: for the pipeline alone, and
  // while the task waits to be run.
  const task = (who, id) => ask(who, 'GET', `/api/pipeline/tasks/${id}`);
  const waiting = await task('pipeline', openTaskId);
  expect(
    'GET /pipeline/tasks/:id of a task that waits',
    [waiting.status, waiting.body],
    [200, OPEN_TASK],
  );
  expect(
    'GET /pipeline/tasks/:id with a user token',
    (await task('alice', openTaskId)).status,
    401,
  );
  expect(
    'GET /pipeline/tasks/:id without a token',
    (await task(undefined, openTaskId)).status,
    401,
  );
  const unknown = randomUUID();
  const missing = await task('pipeline', unknown);
  expectAsMissing(
    'GET /pipeline/tasks/:id of a task that has ended',
    await task('pipeline', taskId),
    missing,
    [taskId, unknown],
  );
  const begun = await ask(
    'pipeline',
    'POST',
    `/api/pipeline/tasks/${openTaskId}/events`,
    {
      json: {
        events: [{ type: 'log', body: { message: 'begun' }, createdAt: now }],
      },
    },
  );
  expect('POST /pipeline/tasks/:id/events', begun.status, 200);
  expectAsMissing(
    'GET /pipeline/tasks/:id of a task that has begun',
    await task('pipeline', openTaskId),
    missing,
    [openTaskId, unknown],
  );
}

/** Unregisters a file as `person`: its row stays, to hide its entities. */
async function unregister(person, target) {
  const answer = await ask(
    person,
    'DELETE',
    `/api/catalog/locations/${locationId(target)}`,
  );
  expect(`DELETE /locations/:id of ${target}`, answer.status, 204);
  unregistered.set(target, registrations.get(target));
  registrations.delete(target);
}

/**
 * Unregistering: the file is registered no more, and its entities, which
 * stay in the catalog until a sync has run without them, are nobody's.
 * Every route is asked again afterwards.
 */
async function unregistering() {
  // A file nobody has claimed is an administrator's to remove.
  await unregister('alice', MADE.nobody);
  // Carol, an administrator in the north organisation, removes its file.
  await unregister('carol', TARGETS.north);
  shownTo.north = null;
  expectRows('an unregistered file keeps its row');
  await expectPipelineFiles(
    'GET /pipeline/locations leaves out what was unregistered',
  );
}

const registeredAt = target =>
  select(`SELECT created_at FROM locations WHERE target = ${quote(target)}`)[0]
    ?.created_at;
let aliceRegisteredAt;

/**
 * A file that was unregistered stays so for every other account: a
 * template run of Dave's that registers Alice's does nothing, or he would
 * be shown what the catalog still holds of hers.
 */
async function registeringForAnother() {
  aliceRegisteredAt = registeredAt(TARGETS.alice);
  await unregister('alice', TARGETS.alice);
  shownTo.alice = null;
  expectRows('her unregistered file keeps its row');

  for (const target of [
    TARGETS.alice,
    // In other letters, and at its other address: it is the same file.
    TARGETS.alice.replace('/alice/', '/ALICE/'),
    TARGETS.alice.replace('/blob/', '/tree/'),
  ]) {
    const answer = await ask('pipeline', 'POST', '/api/pipeline/locations', {
      json: { type: 'url', target, taskId },
    });
    expect(`POST /pipeline/locations ${target}`, answer.status, 200);
  }
  expectRows('a file being removed is not registered for another account');
  await expectPipelineFiles('GET /pipeline/locations still leaves it out');
}

/** For the account that had it, it is registered again: as of now. */
async function registeringAgain() {
  // A run of Alice's own, spelling the address its own way.
  const answer = await ask('pipeline', 'POST', '/api/pipeline/locations', {
    json: {
      type: 'url',
      target: respelled(TARGETS.alice),
      taskId: openTaskId,
    },
  });
  expect(
    'POST /pipeline/locations of an unregistered file',
    [answer.status, answer.body?.target],
    [200, TARGETS.alice],
  );
  unregistered.delete(TARGETS.alice);
  registrations.set(TARGETS.alice, ACCOUNTS.alice);
  shownTo.alice = ACCOUNTS.alice;
  expectRows('a file registered again by its account is theirs again');
  expect(
    'a file registered again is registered as of now',
    registeredAt(TARGETS.alice) > aliceRegisteredAt,
    true,
  );
  await expectPipelineFiles('GET /pipeline/locations has it again');
}

/**
 * The rows of a whole catalog, by table, as the pipeline sends them: what
 * this run put in, less the people who signed in, whom a sync puts back
 * itself, and less what came from the files of `without`.
 */
function catalogRows(without) {
  const gone = entities.filter(one =>
    without.some(owner => one.origin === originOf(owner)),
  );
  // As a catalog would be without them: nothing points at what is gone.
  const kept = entities
    .filter(one => !users.includes(one) && !gone.includes(one))
    .map(one => ({
      ...one,
      value: {
        ...one.value,
        relations: one.value.relations.filter(
          ({ targetRef }) => !gone.some(({ ref }) => ref === targetRef),
        ),
      },
    }));
  const left = [
    ...PEOPLE.map(personTitle),
    ...without.flatMap(owner => [documentTitle(owner), pageTitle(owner)]),
  ];
  return {
    final_entities: kept.map(({ id, ref, value }) => [
      id,
      ref,
      JSON.stringify(value),
    ]),
    search: kept.flatMap(searchRows),
    refresh_state_references: REFERENCES.filter(
      ([source, target]) =>
        !without.some(
          owner =>
            source === locationRef(TARGETS[owner]) ||
            target === componentRef(owner),
        ),
    ),
    search_documents: documents
      .filter(([, document]) => !left.includes(document.title))
      .map(([type, document]) => [
        document.title,
        document.text,
        type,
        JSON.stringify(document),
      ]),
    techdocs_sites: DOCUMENTED.filter(owner => !without.includes(owner)).map(
      owner => [componentRef(owner), siteId(owner)],
    ),
  };
}

/** A catalog sync, as the pipeline makes one: the catalog is replaced. */
async function sync(without = []) {
  const send = async (step, json) => {
    const answer = await ask(
      'pipeline',
      'POST',
      `/api/pipeline/catalog/${step}`,
      { json },
    );
    if (answer.status !== 200) {
      throw new Error(
        `catalog/${step} answered ${answer.status}: ${answer.text}`,
      );
    }
    return answer.body;
  };
  const { syncId } = await send('begin');
  for (const [table, rows] of Object.entries(catalogRows(without))) {
    await send('rows', { syncId, table, rows });
  }
  await send('commit', { syncId });
}

const overridden = () =>
  select(
    `SELECT entity_ref FROM ownership_overrides WHERE entity_ref IN ${inList(
      COMPONENTS.map(componentRef),
    )} ORDER BY entity_ref`,
  ).map(row => row.entity_ref);

/**
 * The first sync after the north file was unregistered runs without its
 * entities. The row stays all the same: a sync that began before the file
 * was unregistered may still be on its way. An owner assigned in the
 * portal goes with the entity it was assigned to.
 */
async function syncingWithout() {
  execute(
    insert(
      'ownership_overrides',
      ['entity_ref', 'new_owner'],
      ['north', 'shared'].map(owner => [
        componentRef(owner),
        `group:default/${SHARED_TEAM}`,
      ]),
    ),
  );
  await sync(['north']);
  expectRows('a file unregistered a moment ago keeps its row');
  expect('an override goes with its entity', overridden(), [
    componentRef('shared'),
  ]);
  // The one that stays would change what the ownership lists say.
  execute(
    `DELETE FROM ownership_overrides WHERE entity_ref = ${quote(
      componentRef('shared'),
    )};`,
  );
}

/**
 * And here is that sync: it read the north file while it was registered,
 * and brings its entities back. They are hidden, by the row that stayed.
 */
async function syncingLate() {
  await sync();
  expectRows('a sync that brings its entities back finds the row');
}

/**
 * Hours later, when no sync that knew the file can be running: its row
 * stays while the catalog holds its entities, and that of a file that has
 * none goes.
 */
async function syncingLater() {
  execute(
    `UPDATE locations SET removed_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now', '-3 hours') WHERE removed_at IS NOT NULL AND instr(lower(target), ${quote(
      `privacy-check-${run}`,
    )}) > 0;`,
  );
  await sync();
  unregistered.delete(MADE.nobody);
  expectRows('a sync that holds its entities keeps an unregistered file');
}

/** A sync without them, hours later: only then does the row go. */
async function syncingLaterWithout() {
  await sync(['north']);
  unregistered.delete(TARGETS.north);
  expectRows('a sync without its entities lets an unregistered file go');
}

const REGISTER_FILE =
  process.env.REGISTER_FILE && new URL(process.env.REGISTER_FILE).href;
// The same file as a template run records it, and in other letters.
const REGISTER_FILE_AGAIN = REGISTER_FILE?.replace('/blob/', '/tree/').replace(
  /[^/]+$/,
  name => name.toUpperCase(),
);
// Condition on a `locations` row: it is that file, at either address.
const IS_REGISTER_FILE =
  REGISTER_FILE &&
  `type = 'url' AND lower(target) IN (${quote(
    REGISTER_FILE.toLowerCase(),
  )}, ${quote(REGISTER_FILE_AGAIN.toLowerCase())})`;

/** Registering a file: whose it becomes, and who is told it is registered. */
async function registering() {
  const register = (person, query = '', target = REGISTER_FILE) =>
    ask(person, 'POST', `/api/catalog/locations${query}`, {
      json: { type: 'url', target },
    });
  const exists = async (person, target) => {
    const answer = await register(person, '?dryRun=true', target);
    return [answer.status, answer.body?.exists];
  };
  const rowsThat = were =>
    select(
      `SELECT target, account FROM locations WHERE removed_at IS ${were} NULL AND ${IS_REGISTER_FILE} ORDER BY target`,
    );
  const filed = () => rowsThat('');
  const unregisteredRows = () => rowsThat('NOT');
  const listedFor = async person =>
    (await ask(person, 'GET', '/api/catalog/locations')).body
      .map(({ data }) => data.target)
      .filter(target => target === REGISTER_FILE);
  const conflict = {
    error: {
      name: 'ConflictError',
      message: `Location url:${REGISTER_FILE} already exists`,
    },
  };
  const refusal = answer => [answer.status, { error: answer.body?.error }];
  const leaving = {
    error: {
      name: 'ConflictError',
      message: `Location url:${REGISTER_FILE} is being removed. Register it again in a few hours`,
    },
  };

  // A file that is in the catalog without having been registered is one
  // the operator configured, and everyone's. It stays so: registered, it
  // would be one account's. The catalog may spell its address otherwise.
  const configured = entity(
    'Component',
    `configured-${run}`,
    `url:${respelled(REGISTER_FILE)}`,
    { type: 'configured' },
  );
  execute(
    insert(
      'final_entities',
      ['entity_id', 'entity_ref', 'final_entity'],
      [[configured.id, configured.ref, JSON.stringify(configured.value)]],
    ),
  );
  expect('dry run of a file the operator configured', await exists('alice'), [
    201,
    true,
  ]);
  expect(
    'POST /locations of a file the operator configured',
    refusal(await register('alice')),
    [409, conflict],
  );
  expect('a configured file is not filed', filed(), []);
  execute(
    `DELETE FROM final_entities WHERE entity_id = ${quote(configured.id)};`,
  );

  expect('dry run of a file nobody registered', await exists('alice'), [
    201,
    false,
  ]);
  expect(
    'POST /locations, not an administrator',
    (await register('bob')).status,
    403,
  );
  expect('nothing is filed for someone who is refused', filed(), []);

  // Alice is in no organisation: what she registers is her own.
  const first = await register('alice');
  expect(
    'POST /locations of a new file',
    [first.status, first.body?.location?.target, first.body?.entities],
    [201, REGISTER_FILE, []],
  );
  expect('a new file is filed under who registered it', filed(), [
    { target: REGISTER_FILE, account: ACCOUNTS.alice },
  ]);
  expect('dry run, by its account', await exists('alice'), [201, true]);
  expect('dry run, by another account', await exists('carol'), [201, false]);
  expect('GET /locations of its account', await listedFor('alice'), [
    REGISTER_FILE,
  ]);
  expect('GET /locations of another account', await listedFor('carol'), []);

  // Spelled with a percent code, it is the same file.
  const spelled = await register(
    'alice',
    '?dryRun=true',
    respelled(REGISTER_FILE),
  );
  expect(
    'dry run of the file spelled another way',
    [spelled.status, spelled.body?.exists, spelled.body?.location?.target],
    [201, true, REGISTER_FILE],
  );
  expect(
    'POST /locations of the file spelled another way, by another account',
    refusal(await register('carol', '', respelled(REGISTER_FILE))),
    [409, conflict],
  );
  expect('it is one file however it is spelled', filed(), [
    { target: REGISTER_FILE, account: ACCOUNTS.alice },
  ]);

  // Registered already: the same refusal for whose it is and whose it is
  // not, and it stays whose it was.
  const mine = await register('alice');
  const theirs = await register('carol');
  expect('POST /locations again, by its account', refusal(mine), [
    409,
    conflict,
  ]);
  expect('POST /locations again, by another account', refusal(theirs), [
    409,
    conflict,
  ]);
  expect(
    'POST /locations with onConflict=refresh, by another account',
    refusal(await register('carol', '?onConflict=refresh')),
    [409, conflict],
  );
  expect(
    'POST /locations with onConflict=refresh, by its account',
    (await register('alice', '?onConflict=refresh')).status,
    201,
  );
  expect('a registered file stays whose it was', filed(), [
    { target: REGISTER_FILE, account: ACCOUNTS.alice },
  ]);

  // Nobody's: whoever registers it next takes it, and is answered as for a
  // new file. Carol is in the north organisation, so it becomes theirs.
  execute(`UPDATE locations SET account = NULL WHERE ${IS_REGISTER_FILE};`);
  expect('dry run of a file nobody has claimed', await exists('carol'), [
    201,
    false,
  ]);
  expect(
    "GET /locations, nobody's file, an administrator",
    await listedFor('alice'),
    [REGISTER_FILE],
  );
  expect(
    "GET /locations, nobody's file, anyone else",
    await listedFor('bob'),
    [],
  );
  const taken = await register('carol');
  expect(
    'POST /locations of a file nobody has claimed',
    [taken.status, taken.body?.location?.target, taken.body?.entities],
    [201, REGISTER_FILE, []],
  );
  expect('a claimed file is filed under the organisation', filed(), [
    { target: REGISTER_FILE, account: ACCOUNTS.north },
  ]);
  expect(
    'POST /locations of a file since claimed',
    refusal(await register('alice')),
    [409, conflict],
  );
  expect('GET /locations, a colleague', await listedFor('dave'), [
    REGISTER_FILE,
  ]);
  expect('GET /locations, the account it left', await listedFor('alice'), []);

  // Removing it is for its account.
  const id = locationId(REGISTER_FILE);
  if (
    (await ask('alice', 'GET', `/api/catalog/locations/${id}`)).status === 404
  ) {
    expect(
      "DELETE /locations/:id of another account's",
      (await ask('alice', 'DELETE', `/api/catalog/locations/${id}`)).status,
      404,
    );
  } else {
    expect("GET /locations/:id of another account's", 'shown', 'not found');
  }
  expect('a file is not removed by another account', filed().length, 1);
  expect(
    'DELETE /locations/:id of her own',
    (await ask('carol', 'DELETE', `/api/catalog/locations/${id}`)).status,
    204,
  );
  expect('an unregistered file is registered no more', filed(), []);
  expect('an unregistered file keeps its row', unregisteredRows(), [
    { target: REGISTER_FILE, account: ACCOUNTS.north },
  ]);
  expect('dry run of an unregistered file', await exists('carol'), [
    201,
    false,
  ]);
  expect('GET /locations of the account it was', await listedFor('dave'), []);

  // Its entities are in the catalog until a sync has run without them. For
  // another account it stays unregistered till then: registered now, they
  // would be shown what is left of the north organisation's.
  expect(
    'POST /locations of a file being removed, by another account',
    refusal(await register('alice')),
    [409, leaving],
  );
  expect('a file being removed stays so for another account', filed(), []);

  // For the account that had it, it is registered again.
  const again = await register('carol');
  expect(
    'POST /locations of a file being removed, by its account',
    [again.status, again.body?.location?.target, again.body?.entities],
    [201, REGISTER_FILE, []],
  );
  expect('a file registered again by its account is theirs', filed(), [
    { target: REGISTER_FILE, account: ACCOUNTS.north },
  ]);
  expect('nothing is left of its having been removed', unregisteredRows(), []);
  expect('GET /locations of its account again', await listedFor('dave'), [
    REGISTER_FILE,
  ]);
  expect(
    'GET /locations of another account still',
    await listedFor('alice'),
    [],
  );
  execute(`DELETE FROM locations WHERE ${IS_REGISTER_FILE};`);

  // The same file as a template run records it, in other letters, is
  // Bob's: registered for Alice it is refused, and filed nowhere else.
  execute(
    insert(
      'locations',
      ['type', 'target', 'account'],
      [['url', REGISTER_FILE_AGAIN, ACCOUNTS.bob]],
    ),
  );
  expect(
    'dry run of a file registered at its other address',
    await exists('alice'),
    [201, false],
  );
  expect(
    'POST /locations of a file registered at its other address',
    refusal(await register('alice')),
    [409, conflict],
  );
  expect('it is filed once', filed(), [
    { target: REGISTER_FILE_AGAIN, account: ACCOUNTS.bob },
  ]);

  // Unregistered at that address, it is the same file being removed.
  execute(
    `UPDATE locations SET removed_at = '${now}' WHERE ${IS_REGISTER_FILE};`,
  );
  expect(
    'POST /locations of a file being removed at its other address',
    refusal(await register('alice')),
    [409, leaving],
  );
  expect('it is not filed at this address meanwhile', filed(), []);
  expect('the row of its other address stays', unregisteredRows(), [
    { target: REGISTER_FILE_AGAIN, account: ACCOUNTS.bob },
  ]);
}

/** Runs one named part and says how it went. */
async function report(name, part) {
  problems = [];
  const before = checks;
  try {
    await part();
  } catch (error) {
    problems.push(`could not be checked: ${error.stack ?? error}`);
  }
  console.log(
    `${problems.length ? 'FAIL' : 'ok  '} ${name} (${checks - before} checks)`,
  );
  for (const problem of problems) {
    console.log(`  ${problem}`);
  }
  return problems.length;
}

// The page the Worker serves names the owner of the repository it starts
// workflows in (edge/src/index.ts).
const repositoryOwner = /"githubOrg":"([^"]*)"/.exec(
  await fetch(`${EDGE}/`).then(
    response => response.text(),
    () => '',
  ),
)?.[1];
if (repositoryOwner !== PORTAL_REPOSITORY.split('/')[0]) {
  console.error(
    `The Worker at ${EDGE} ${
      repositoryOwner === undefined
        ? 'does not say which repository it starts workflows in'
        : `starts workflows in a repository of ${repositoryOwner}`
    }. Start it with: yarn dev --var PORTAL_REPO:${PORTAL_REPOSITORY}`,
  );
  process.exit(1);
}

if (
  REGISTER_FILE &&
  select(`SELECT 1 AS found FROM locations WHERE ${IS_REGISTER_FILE}`).length
) {
  // Before anything is put in: what is taken out at the end includes it.
  console.error(
    `${REGISTER_FILE} is registered in this database already. Name a file that is not as REGISTER_FILE.`,
  );
  process.exit(1);
}

// A sync replaces the whole catalog: one is made only where the catalog
// holds nothing but what this check puts in.
const [{ held }] = select(
  `SELECT ${[
    'final_entities',
    'search',
    'refresh_state_references',
    'search_documents',
    'techdocs_sites',
    'signed_in_users',
  ]
    .map(table => `(SELECT count(*) FROM ${table})`)
    .join(' + ')} AS held`,
);
const skipped = [];

let failed = 0;
/** Asks every route as every person; `after` says what was done since. */
async function askEveryone(after = '') {
  for (const [name, section] of Object.entries(sections)) {
    for (const person of PEOPLE) {
      failed += await report(`${name}, as ${person}${after}`, () =>
        section(person),
      );
    }
  }
}
try {
  execute(SEED);
  for (const [key, type, content] of siteObjects) {
    const put = await fetch(`${EDGE}/api/pipeline/techdocs/object/${key}`, {
      method: 'PUT',
      headers: {
        authorization: `Bearer ${pipelineToken}`,
        'content-type': type,
      },
      body: content,
    });
    if (!put.ok) {
      throw new Error(
        `Could not store ${key}: ${put.status} ${await put.text()}`,
      );
    }
  }
  await askEveryone();
  failed += await report(
    'overrides, pipeline registrations and tasks',
    together,
  );
  failed += await report('unregistering files', unregistering);
  await askEveryone(', after files were unregistered');
  failed += await report(
    'registering an unregistered file for another account',
    registeringForAnother,
  );
  await askEveryone(', after another account tried to register one');
  failed += await report(
    'registering an unregistered file again',
    registeringAgain,
  );
  await askEveryone(', after its account registered it again');
  if (held === 0) {
    for (const [name, part, after] of [
      ['a sync without its entities', syncingWithout, 'a sync without them'],
      [
        'a late sync that brings them back',
        syncingLate,
        'a late sync with them',
      ],
      [
        'a sync with its entities, hours later',
        syncingLater,
        'a sync with them hours later',
      ],
      [
        'a sync without them, hours later',
        syncingLaterWithout,
        'a sync without them hours later',
      ],
    ]) {
      failed += await report(name, part);
      await askEveryone(`, after ${after}`);
    }
  } else {
    skipped.push('What a catalog sync does with an unregistered file');
    console.log(
      'skip catalog syncs (this catalog holds more than the check put in)',
    );
  }
  if (REGISTER_FILE) {
    failed += await report('registering a file', registering);
  } else {
    skipped.push('Registering a file');
    console.log('skip registering a file (REGISTER_FILE is not set)');
  }
} finally {
  execute(
    [
      CLEANUP,
      REGISTER_FILE &&
        `DELETE FROM locations WHERE ${IS_REGISTER_FILE};\nDELETE FROM final_entities WHERE entity_ref = ${quote(
          `component:default/configured-${run}`,
        )};`,
      // What a sync that failed half-way left behind.
      held === 0 &&
        `${Object.keys(catalogRows([]))
          .map(table => `DELETE FROM staging_${table};`)
          .join('\n')}\nDELETE FROM portal_state WHERE key = 'catalog-sync';`,
    ]
      .filter(Boolean)
      .join('\n'),
  );
  await ask('pipeline', 'POST', '/api/pipeline/techdocs/delete', {
    json: { keys: siteObjects.map(([key]) => key) },
  });
}
console.log(
  failed
    ? `\n${failed} of ${checks} checks found a difference.`
    : `\nAll ${checks} checks passed: every caller is shown their own accounts and nothing of the others.${skipped
        .map(what => ` ${what} was not checked.`)
        .join('')}`,
);
process.exit(failed ? 1 : 0);
