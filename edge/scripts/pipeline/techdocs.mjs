// Builds the documentation of catalog entities and stores it with the portal.
//
// Several entities can share one documentation directory (a catalog file
// describing ten components next to one mkdocs.yml). Each distinct directory
// is built once, as a "site" with a stable id, and every entity is mapped to
// its site.
//
// A directory with a mkdocs.yml or a docs directory is built as it is. One
// that documents itself with a README.md alone gets a site made of that
// README and the files it links to.
import { execFile } from 'node:child_process';
import { createHash } from 'node:crypto';
import {
  copyFile,
  cp,
  lstat,
  mkdir,
  readFile,
  readdir,
  stat,
  writeFile,
} from 'node:fs/promises';
import { availableParallelism } from 'node:os';
import {
  basename,
  dirname,
  isAbsolute,
  join,
  relative,
  resolve,
  sep,
} from 'node:path';
import { Writable } from 'node:stream';
import { promisify } from 'node:util';
import { ConfigReader } from '@backstage/config';
import { ScmIntegrations } from '@backstage/integration';
import {
  TechdocsGenerator,
  getLocationForEntity,
} from '@backstage/plugin-techdocs-node';
import mime from 'mime-types';
import { parse, stringify } from 'yaml';
import { portalRequest } from './portal.mjs';
import { repoRoot } from './settings.mjs';

const TECHDOCS_ANNOTATION = 'backstage.io/techdocs-ref';
const BUILD_CONCURRENCY = Math.min(availableParallelism(), 8);
const UPLOAD_CONCURRENCY = 8;
const DELETE_BATCH = 500;
// mkdocs stamps this time into sitemaps instead of the clock, and the site
// metadata is given the same one. Pinning it makes a build of unchanged
// sources byte-for-byte identical, so nothing is uploaded again.
const BUILD_EPOCH_SECONDS = Date.UTC(2000, 0, 1) / 1000;
// mkdocs makes a file of exactly this name the index page of its directory.
const README = 'README.md';
// What a source directory with its own documentation set-up holds.
const DOCS_SETUP = new Set(['mkdocs.yml', 'mkdocs.yaml', 'docs']);
const MARKDOWN_FILE = /\.(?:md|markdown)$/i;
// Where Markdown and the HTML inside it point: `](target)` and `](<target>)`
// of links and images, `[label]: target` reference definitions, and `src`
// and `href` attributes.
const LINK_TARGETS =
  /\]\(\s*(?:<([^<>\n]+)>|([^\s<>()]+))|^ {0,3}\[[^\]\n]+\]:\s*<?([^\s<>]+)|\b(?:src|href)\s*=\s*["']([^"'\n]+)["']/gm;
// A target with a scheme, or one that starts at the root of a host.
const NOT_RELATIVE = /^(?:[a-z][a-z0-9+.-]*:|\/)/i;

const execFileAsync = promisify(execFile);

/** A Backstage logger that passes warnings and errors on and drops the rest. */
function loggerTo(record) {
  const logger = {
    debug() {},
    info() {},
    warn: record,
    error: record,
    child: () => logger,
  };
  return logger;
}

/** Fails early, and plainly, when the documentation tools are not installed. */
export async function assertDocsToolchain() {
  for (const tool of ['mkdocs', 'd2']) {
    try {
      await execFileAsync(tool, ['--version']);
    } catch {
      throw new Error(
        `${tool} was not found on the PATH. Documentation is built with the TechDocs toolchain: see "Cloudflare Workers Deployment" in the README.`,
      );
    }
  }
}

/** Runs `task` over `items`, at most `limit` at a time, keeping the order. */
async function inParallel(items, limit, task) {
  const results = new Array(items.length);
  let next = 0;
  const worker = async () => {
    while (next < items.length) {
      const index = next++;
      results[index] = await task(items[index]);
    }
  };
  await Promise.all(
    Array.from({ length: Math.min(limit, items.length) }, worker),
  );
  return results;
}

/** A storage-safe id that stays the same for the same source, run after run. */
function siteIdFor(sourceKey) {
  const slug = sourceKey
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48)
    .replace(/-+$/, '');
  const hash = createHash('sha1').update(sourceKey).digest('hex').slice(0, 10);
  return slug ? `${slug}-${hash}` : hash;
}

/** `https://host/owner/repo[/tree|blob/<branch and path>]` taken apart. */
function parseRepositoryUrl(target) {
  const url = new URL(target);
  const [owner, repo, marker, ...rest] = url.pathname
    .split('/')
    .filter(Boolean)
    .map(decodeURIComponent);
  if (!owner || !repo || (marker && marker !== 'tree' && marker !== 'blob')) {
    throw new Error(`cannot tell the repository and path from ${target}`);
  }
  return {
    origin: url.origin,
    host: url.host,
    repository: `${owner}/${repo.replace(/\.git$/, '')}`,
    // Branch then path. A branch name may contain slashes, so where one ends
    // and the other starts is only known once the branches are.
    branchAndPath: rest.join('/'),
  };
}

/**
 * Where an entity's documentation sources are: a directory on this machine
 * (`dir`), or a path in another repository that has to be cloned (`remote`).
 * `key` names the source the same way wherever the pipeline runs.
 */
function docsSource(entity, integrations, github) {
  const location = getLocationForEntity(entity, integrations);
  if (location.type === 'dir') {
    const inRepo = relative(repoRoot, location.target);
    const isInRepo = !inRepo.startsWith('..') && !isAbsolute(inRepo);
    return {
      key: isInRepo ? inRepo.split(sep).join('/') || '.' : location.target,
      dir: location.target,
    };
  }
  const parsed = parseRepositoryUrl(location.target);
  const ownBranch = github && `${github.refName}/`;
  if (
    github &&
    parsed.origin === new URL(github.serverUrl).origin &&
    parsed.repository.toLowerCase() === github.repository.toLowerCase() &&
    `${parsed.branchAndPath}/`.startsWith(ownBranch)
  ) {
    // This repository at the branch that is checked out: no need to clone.
    const path = `${parsed.branchAndPath}/`
      .slice(ownBranch.length)
      .replace(/\/+$/, '');
    return {
      key: path || '.',
      dir: resolve(repoRoot, path),
      editLocation: location,
    };
  }
  return {
    key: `${parsed.host}/${parsed.repository}/${parsed.branchAndPath}`.replace(
      /\/+$/,
      '',
    ),
    remote: parsed,
    editLocation: location,
  };
}

/**
 * Runs git without a prompt. The token is passed as a request header through
 * the environment, limited to its own host: it never appears in the command
 * line, in git's config files or in the cloned repository.
 */
function git(args, credentials) {
  return execFileAsync('git', args, {
    env: {
      ...process.env,
      GIT_TERMINAL_PROMPT: '0',
      ...(credentials?.token && {
        GIT_CONFIG_COUNT: '1',
        GIT_CONFIG_KEY_0: `http.${credentials.origin}/.extraheader`,
        GIT_CONFIG_VALUE_0: `Authorization: Basic ${Buffer.from(
          `x-access-token:${credentials.token}`,
        ).toString('base64')}`,
      }),
    },
    maxBuffer: 16 * 1024 * 1024,
  });
}

/**
 * Makes a shallow clone holding the given branch-and-path and returns the
 * directory the path points at.
 */
async function cloneRemote(remote, clonesDir, credentials) {
  const repositoryUrl = `${remote.origin}/${remote.repository}.git`;
  let branch;
  if (remote.branchAndPath) {
    const { stdout } = await git(
      ['ls-remote', '--heads', '--tags', repositoryUrl],
      credentials,
    );
    const names = stdout
      .split('\n')
      .map(line => line.split('\t')[1]?.replace(/^refs\/(heads|tags)\//, ''))
      .filter(name => name && !name.endsWith('^{}'));
    branch = names
      .filter(name => `${remote.branchAndPath}/`.startsWith(`${name}/`))
      .sort((a, b) => b.length - a.length)[0];
    if (!branch) {
      throw new Error(
        `no branch or tag of ${remote.repository} matches ${remote.branchAndPath}`,
      );
    }
  }
  const directory = join(
    clonesDir,
    siteIdFor(`${remote.host}/${remote.repository}/${branch ?? ''}`),
  );
  const cloned = await stat(directory).then(
    () => true,
    () => false,
  );
  if (!cloned) {
    await git(
      [
        'clone',
        '--quiet',
        '--depth',
        '1',
        ...(branch ? ['--branch', branch] : []),
        repositoryUrl,
        directory,
      ],
      credentials,
    );
  }
  const path = branch ? remote.branchAndPath.slice(branch.length + 1) : '';
  return resolve(directory, path);
}

const HTML_ENTITIES = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
};

/** What Backstage's collator does to the titles and text mkdocs escaped. */
const unescapeHtml = text =>
  text.replace(/&(?:amp|lt|gt|quot|#39);/g, entity => HTML_ENTITIES[entity]);

/**
 * The search documents Backstage's TechDocs collator builds: one for every
 * section of the site, for every entity the site documents.
 */
function searchDocuments(site, sections) {
  return site.entities.flatMap(({ entity }) => {
    const kind = entity.kind.toLowerCase();
    const namespace = (entity.metadata.namespace || 'default').toLowerCase();
    const name = entity.metadata.name.toLowerCase();
    const owner = entity.relations
      ?.find(relation => relation.type === 'ownedBy')
      ?.targetRef.split('/')
      .pop();
    return sections.map(section => {
      const document = {
        title: unescapeHtml(section.title),
        text: unescapeHtml(section.text || ''),
        location: `/docs/${namespace}/${kind}/${name}/${section.location}`,
        path: section.location,
        kind,
        namespace,
        name,
        entityTitle: entity.metadata.title,
        componentType: entity.spec?.type?.toString() || 'other',
        lifecycle: entity.spec?.lifecycle || '',
        owner: owner || '',
      };
      return [
        document.title,
        document.text,
        'techdocs',
        JSON.stringify(document),
      ];
    });
  });
}

/**
 * Whether a source directory documents itself with a README alone: it has
 * one, and neither a mkdocs configuration nor a docs directory.
 */
async function hasOnlyReadme(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  return (
    !entries.some(entry => DOCS_SETUP.has(entry.name)) &&
    entries.some(entry => entry.name === README && entry.isFile())
  );
}

/**
 * The files under `root` that the Markdown file `file` links to or embeds,
 * as paths from `root`. A link to a directory counts as one to its index
 * page. Links that lead out of `root`, to something that is not there or to
 * a symbolic link are left out.
 */
async function linkedFiles(root, file) {
  const text = await readFile(join(root, file), 'utf8');
  const linked = [];
  for (const [, ...groups] of text.matchAll(LINK_TARGETS)) {
    const target = groups.find(Boolean).replace(/[?#].*$/, '');
    if (!target || NOT_RELATIVE.test(target)) {
      continue;
    }
    let path;
    try {
      path = relative(
        root,
        resolve(root, dirname(file), decodeURIComponent(target)),
      );
    } catch {
      continue;
    }
    if (!path || path.startsWith('..') || isAbsolute(path)) {
      continue;
    }
    const found = await lstat(join(root, path)).catch(() => undefined);
    if (found?.isFile()) {
      linked.push(path);
    } else if (found?.isDirectory()) {
      // mkdocs serves either of these as the page of a directory.
      for (const page of [join(path, 'index.md'), join(path, README)]) {
        const index = await lstat(join(root, page)).catch(() => undefined);
        if (index?.isFile()) {
          linked.push(page);
          break;
        }
      }
    }
  }
  return linked;
}

/**
 * `repo_url` and `edit_uri` for pages that lie directly in the source
 * directory. The generator can only point them at a docs directory inside
 * it, and leaves alone what a mkdocs.yml already sets.
 */
function sourceDirEditLinks(editLocation, integrations) {
  if (editLocation?.type !== 'url') {
    return {};
  }
  const { target } = editLocation;
  const editUrl = integrations.byUrl(target)?.resolveEditUrl(target);
  if (!editUrl) {
    return {};
  }
  // A URL that names no branch has no edit form and comes back as it went in.
  return editUrl === target
    ? { repo_url: target }
    : { repo_url: target, edit_uri: editUrl };
}

/**
 * Writes the mkdocs project of a source directory that has only a README: a
 * mkdocs.yml, and a docs directory holding the README and, at the paths they
 * have in the source, the files it links to, followed through every Markdown
 * file reached. The README becomes the home page, its relative links and
 * images work as written, and each page's edit link is its source file.
 */
async function writeReadmeProject(site, inputDir, integrations) {
  const docsDir = join(inputDir, 'docs');
  const copied = new Set();
  const pending = [README];
  while (pending.length > 0) {
    const file = pending.pop();
    if (copied.has(file)) {
      continue;
    }
    copied.add(file);
    await mkdir(dirname(join(docsDir, file)), { recursive: true });
    await copyFile(join(site.dir, file), join(docsDir, file));
    if (MARKDOWN_FILE.test(file)) {
      pending.push(...(await linkedFiles(site.dir, file)));
    }
  }
  await writeFile(
    join(inputDir, 'mkdocs.yml'),
    stringify({
      site_name: site.title,
      docs_dir: 'docs',
      plugins: ['techdocs-core'],
      ...sourceDirEditLinks(site.editLocation, integrations),
    }),
  );
}

/** Builds one site with Backstage's generator. Throws with mkdocs' output. */
async function buildSite(generator, site, workDir, integrations) {
  const inputDir = join(workDir, 'src', site.siteId);
  const outputDir = join(workDir, 'site', site.siteId);
  if (await hasOnlyReadme(site.dir)) {
    await writeReadmeProject(site, inputDir, integrations);
  } else {
    // Built from a copy: the generator rewrites mkdocs.yml and the D2 plugin
    // writes a cache next to it.
    await cp(site.dir, inputDir, {
      recursive: true,
      filter: source => !['.git', 'node_modules'].includes(basename(source)),
    });
  }

  const output = [];
  const record = message => output.push(String(message).trimEnd());
  try {
    await generator.run({
      inputDir,
      outputDir,
      parsedLocationAnnotation: site.editLocation,
      logger: loggerTo(record),
      logStream: new Writable({
        write(chunk, _encoding, done) {
          record(chunk);
          done();
        },
      }),
      siteOptions: { name: site.title },
    });
  } catch (error) {
    // mkdocs explains itself on its ERROR lines; the generator's own message
    // only names the temporary directories involved.
    const reasons = output
      .flatMap(text => text.split('\n'))
      .filter(line => /^ERROR\s+-/.test(line))
      .map(line => line.replace(/^ERROR\s+-\s+/, '').trim());
    throw new Error(
      reasons.length > 0
        ? reasons.slice(0, 3).join('; ')
        : error.cause?.message ?? error.message,
    );
  }

  // Two things would make every build differ from the last and upload again:
  // the build time in the metadata, and the random id the D2 plugin gives
  // each diagram on every run. Both are replaced with values that depend
  // only on the content.
  const metadataPath = join(outputDir, 'techdocs_metadata.json');
  const metadata = JSON.parse(await readFile(metadataPath, 'utf8'));
  const files = metadata.files.toSorted();
  await writeFile(
    metadataPath,
    JSON.stringify({
      ...metadata,
      build_timestamp: BUILD_EPOCH_SECONDS * 1000,
      files,
    }),
  );
  for (const file of files) {
    if (file.endsWith('.html') || file === 'search/search_index.json') {
      const path = join(outputDir, file);
      const ids = new Map();
      const pinned = (await readFile(path, 'utf8')).replace(
        /\bd2-[0-9a-f]{32}\b/g,
        id => {
          if (!ids.has(id)) {
            const stable = createHash('sha1').update(`${file}#${ids.size}`);
            ids.set(id, `d2-${stable.digest('hex').slice(0, 32)}`);
          }
          return ids.get(id);
        },
      );
      if (ids.size > 0) {
        await writeFile(path, pinned);
      }
    }
  }

  const searchIndex = await readFile(
    join(outputDir, 'search/search_index.json'),
    'utf8',
  ).then(JSON.parse, () => ({ docs: [] }));
  return { outputDir, documents: searchDocuments(site, searchIndex.docs) };
}

/**
 * Builds the documentation of every entity that has a techdocs-ref
 * annotation.
 *
 * Returns one entry per distinct documentation source: `{ siteId, source,
 * entities, outputDir, documents }` when it was built and `{ siteId, source,
 * entities, error }` when it was not. `unresolved` lists entities whose
 * annotation could not be turned into a source at all. Nothing here throws
 * for a single bad site.
 */
export async function buildDocs({ entities, dataDir, github, githubToken }) {
  const pipelineConfig = parse(
    await readFile(join(repoRoot, 'app-config.pipeline.yaml'), 'utf8'),
  );
  // Only the host: the token is written in that file as an environment
  // placeholder, and nothing built here should hold the real one.
  const { host } = pipelineConfig.integrations.github[0];
  const config = new ConfigReader({
    techdocs: pipelineConfig.techdocs,
    integrations: { github: [{ host }] },
  });
  const integrations = ScmIntegrations.fromConfig(config);
  const credentials = { origin: `https://${host}`, token: githubToken };

  const sitesByKey = new Map();
  const unresolved = [];
  for (const { entityRef, entity } of entities) {
    if (!entity.metadata.annotations?.[TECHDOCS_ANNOTATION]) {
      continue;
    }
    try {
      const source = docsSource(entity, integrations, github);
      const site = sitesByKey.get(source.key) ?? {
        ...source,
        siteId: siteIdFor(source.key),
        source: source.key,
        title: entity.metadata.title ?? entity.metadata.name,
        entities: [],
      };
      site.entities.push({ entityRef, entity });
      sitesByKey.set(source.key, site);
    } catch (error) {
      unresolved.push({ entityRef, error: error.message });
    }
  }
  const sites = [...sitesByKey.values()].sort((a, b) =>
    a.siteId.localeCompare(b.siteId),
  );

  const workDir = join(dataDir, 'techdocs');
  const clonesDir = join(workDir, 'clones');
  await mkdir(clonesDir, { recursive: true });
  // One at a time: sites of the same repository share a clone.
  for (const site of sites) {
    if (site.remote) {
      try {
        site.dir = await cloneRemote(site.remote, clonesDir, credentials);
      } catch (error) {
        site.error = `could not fetch the sources: ${
          error.stderr?.trim() || error.message
        }`;
      }
    }
  }

  process.env.SOURCE_DATE_EPOCH = String(BUILD_EPOCH_SECONDS);
  const generator = TechdocsGenerator.fromConfig(config, {
    logger: loggerTo(() => {}),
  });
  const built = await inParallel(sites, BUILD_CONCURRENCY, async site => {
    const { siteId, source, entities: documented } = site;
    if (site.error) {
      return { siteId, source, entities: documented, error: site.error };
    }
    try {
      return {
        siteId,
        source,
        entities: documented,
        ...(await buildSite(generator, site, workDir, integrations)),
      };
    } catch (error) {
      return { siteId, source, entities: documented, error: error.message };
    }
  });
  return { sites: built, unresolved };
}

/**
 * Uploads the built sites to the portal's storage, skipping every file the
 * portal already has with the same content.
 *
 * Returns the upload counts and `staleKeys`: stored objects that belong to no
 * current site. They are not deleted here, because the catalog that is live
 * until the next commit may still point at them. A site that failed to build
 * keeps what was stored for it before, and is listed in `keptSiteIds`.
 */
export async function uploadDocs(portal, sites) {
  const manifest = await portalRequest(
    portal,
    'GET',
    '/api/pipeline/techdocs/manifest',
    { retry: true },
  );
  const stored = new Map(manifest.objects.map(({ key, etag }) => [key, etag]));

  const files = [];
  for (const site of sites) {
    if (!site.outputDir) {
      continue;
    }
    const entries = await readdir(site.outputDir, {
      recursive: true,
      withFileTypes: true,
    });
    for (const entry of entries) {
      if (entry.isFile()) {
        const path = join(entry.parentPath, entry.name);
        const within = relative(site.outputDir, path).split(sep).join('/');
        files.push({ path, key: `sites/${site.siteId}/${within}` });
      }
    }
  }

  let uploaded = 0;
  let uploadedBytes = 0;
  await inParallel(files, UPLOAD_CONCURRENCY, async ({ path, key }) => {
    const content = await readFile(path);
    if (createHash('md5').update(content).digest('hex') === stored.get(key)) {
      return;
    }
    await portalRequest(
      portal,
      'PUT',
      `/api/pipeline/techdocs/object/${key
        .split('/')
        .map(encodeURIComponent)
        .join('/')}`,
      {
        body: content,
        contentType:
          mime.contentType(basename(path)) || 'application/octet-stream',
        retry: true,
      },
    );
    uploaded++;
    uploadedBytes += content.length;
  });

  const current = new Set(files.map(file => file.key));
  const keptSiteIds = new Set(
    sites
      .filter(
        site => site.error && stored.has(`sites/${site.siteId}/index.html`),
      )
      .map(site => site.siteId),
  );
  const staleKeys = [...stored.keys()].filter(
    key => !current.has(key) && !keptSiteIds.has(key.split('/')[1]),
  );
  return {
    files: files.length,
    uploaded,
    uploadedBytes,
    unchanged: files.length - uploaded,
    staleKeys,
    keptSiteIds,
  };
}

/** Deletes stored objects that no current site uses. */
export async function deleteStaleDocs(portal, staleKeys) {
  for (let start = 0; start < staleKeys.length; start += DELETE_BATCH) {
    await portalRequest(portal, 'POST', '/api/pipeline/techdocs/delete', {
      json: { keys: staleKeys.slice(start, start + DELETE_BATCH) },
      retry: true,
    });
  }
}
