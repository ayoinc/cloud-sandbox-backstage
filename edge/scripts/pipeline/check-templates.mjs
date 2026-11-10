// Renders software templates with the real scaffolder, without publishing.
//
// Every template has a sample-values.json next to its template.yaml: form
// values a user could have entered. This script hands each template, its
// files and those values to the pipeline backend's dry run, which validates
// the values against the form and runs the steps that only write files. A
// template that cannot be rendered fails here instead of in front of a user.
//
// Each template is then rendered a second time with awkward prose in its
// free-text fields (see AWKWARD_TEXT). Every YAML and JSON file that parsed
// the first time must still parse: a description with a colon or a quote in
// it must not produce a repository whose catalog-info.yaml is refused.
//
//   yarn workspace @internal/edge template:check             every template
//   yarn workspace @internal/edge template:check <dir> ...   those templates
//   ... --out <dir>   also write what each template produced to <dir>/<name>
//
// Paths are relative to the repository root. PIPELINE_DATA_DIR and
// PIPELINE_BACKEND_PORT are honoured as in the other pipeline scripts.
import { readFileSync } from 'node:fs';
import { mkdir, readdir, rm, writeFile } from 'node:fs/promises';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { parse, parseAllDocuments } from 'yaml';
import {
  backendLogTail,
  backendRequest,
  prepareDataDir,
  startBackend,
  writeRunConfig,
} from './backend.mjs';
import { dataDirFor, repoRoot } from './settings.mjs';

const TEMPLATE_ROOTS = ['templates', 'catalog/terraform-modules/templates'];
const SAMPLE_VALUES = 'sample-values.json';
// Template syntax that should have been replaced by a value: the contexts a
// skeleton is rendered with. GitHub Actions expressions such as
// ${{ github.sha }} or ${{ steps.build.outputs.tag }} are meant to survive.
const UNRENDERED = /\$\{\{\s*(values|parameters)\b[^}]*\}\}/;

async function filesUnder(dir) {
  const entries = await readdir(dir, { recursive: true, withFileTypes: true });
  return entries
    .filter(entry => entry.isFile())
    .map(entry => join(entry.parentPath, entry.name));
}

/** Directories holding a template.yaml that defines a Template. */
async function findTemplates() {
  const found = [];
  for (const root of TEMPLATE_ROOTS) {
    for (const file of await filesUnder(join(repoRoot, root))) {
      if (
        file.endsWith(`${sep}template.yaml`) &&
        /^kind:\s*Template\s*$/m.test(readFileSync(file, 'utf8'))
      ) {
        found.push(dirname(file));
      }
    }
  }
  return found.sort();
}

// What a person may well type into a description: an apostrophe, quotes, a
// colon followed by a space, a percent sign, a hash and an ampersand all
// mean something to YAML or JSON when pasted in unquoted.
const AWKWARD_TEXT = `It's the team's "main" service: handles 50% of #1 & more`;
const PROSE_FIELD =
  /descri|summary|purpose|title|about|notes?$|comment|message|tagline|headline/i;

/**
 * The form fields a user writes prose in: strings with no pattern, format,
 * fixed choices or picker, named like a description or a title.
 */
function proseFields(template) {
  const fields = new Map();
  for (const page of [template.spec?.parameters ?? []].flat()) {
    for (const [key, schema] of Object.entries(page?.properties ?? {})) {
      if (
        schema?.type === 'string' &&
        !schema.enum &&
        !schema.pattern &&
        !schema.format &&
        !schema['ui:field'] &&
        PROSE_FIELD.test(`${key} ${schema.title ?? ''}`)
      ) {
        fields.set(key, AWKWARD_TEXT.slice(0, schema.maxLength ?? Infinity));
      }
    }
  }
  return fields;
}

/** Whether the text of a .yaml, .yml or .json file parses; undefined for other files. */
function parses({ path, content }) {
  const text = content.toString('utf8');
  if (/\.ya?ml$/.test(path)) {
    return parseAllDocuments(text).every(document => !document.errors.length);
  }
  if (/\.json$/.test(path)) {
    try {
      JSON.parse(text);
      return true;
    } catch {
      return false;
    }
  }
  return undefined;
}

/** Renders one template. Returns `{ name, files }` or throws with the reason. */
async function renderTemplate(backend, dir) {
  const template = parse(readFileSync(join(dir, 'template.yaml'), 'utf8'));
  let sample;
  try {
    sample = JSON.parse(readFileSync(join(dir, SAMPLE_VALUES), 'utf8'));
  } catch (error) {
    throw new Error(
      error.code === 'ENOENT'
        ? `There is no ${SAMPLE_VALUES} next to template.yaml.`
        : `${SAMPLE_VALUES} is not valid JSON: ${error.message}`,
    );
  }

  const directoryContents = (await filesUnder(dir))
    .filter(file => file !== join(dir, SAMPLE_VALUES))
    .map(file => ({
      path: relative(dir, file).split(sep).join('/'),
      base64Content: readFileSync(file).toString('base64'),
    }));
  /** What the steps write with these form values: the new repository. */
  const render = async values => {
    let result;
    try {
      result = await backendRequest(backend, '/api/scaffolder/v2/dry-run', {
        method: 'POST',
        json: { template, values, secrets: {}, directoryContents },
      });
    } catch (error) {
      // The scaffolder answers 400 with the schema errors of the form values.
      const invalid = error.body?.errors?.map(e => e.stack ?? e.message);
      throw invalid
        ? new Error(`The values were rejected: ${invalid.join('; ')}`)
        : error;
    }
    return result.directoryContents.map(file => ({
      path: file.path,
      content: Buffer.from(file.base64Content, 'base64'),
    }));
  };

  const files = await render(sample.values);
  const unrendered = files
    .filter(file => UNRENDERED.test(file.content.toString('utf8')))
    .map(file => file.path);
  if (unrendered.length > 0) {
    throw new Error(
      `Template syntax was left in ${unrendered.length} files: ${unrendered
        .slice(0, 5)
        .join(', ')}`,
    );
  }

  const prose = proseFields(template);
  if (prose.size > 0) {
    let awkward;
    try {
      awkward = await render({
        ...sample.values,
        ...Object.fromEntries(prose),
      });
    } catch (error) {
      throw new Error(
        `With ${[...prose.keys()].join(', ')} set to ${JSON.stringify(
          AWKWARD_TEXT,
        )}: ${error.message.split('\n')[0]}`,
      );
    }
    const sound = new Set(
      files.filter(file => parses(file) === true).map(file => file.path),
    );
    const broken = awkward
      .filter(file => sound.has(file.path) && parses(file) === false)
      .map(file => file.path);
    if (broken.length > 0) {
      throw new Error(
        `Free text breaks ${broken.length} files. With ${[...prose.keys()].join(
          ', ',
        )} set to ${JSON.stringify(
          AWKWARD_TEXT,
        )} these no longer parse: ${broken.slice(0, 6).join(', ')}`,
      );
    }
  }
  return { name: template.metadata.name, files };
}

async function main() {
  const args = process.argv.slice(2);
  const outFlag = args.indexOf('--out');
  const outDir =
    outFlag === -1 ? undefined : resolve(repoRoot, args[outFlag + 1] ?? '');
  if (outFlag !== -1) {
    args.splice(outFlag, 2);
  }
  const dirs =
    args.length > 0
      ? args.map(dir => resolve(repoRoot, dir))
      : await findTemplates();

  const dataDir = dataDirFor('pipeline-templates');
  await prepareDataDir(dataDir);
  // The dry run uses no catalog entity; the backend reads the catalog anyway.
  await writeRunConfig(dataDir, { github: undefined, registered: [] });
  const backend = await startBackend({ dataDir });
  const failures = [];
  try {
    for (const dir of dirs) {
      const label = relative(repoRoot, dir);
      try {
        const { name, files } = await renderTemplate(backend, dir);
        if (outDir) {
          const target = join(outDir, name);
          await rm(target, { recursive: true, force: true });
          for (const file of files) {
            await mkdir(dirname(join(target, file.path)), { recursive: true });
            await writeFile(join(target, file.path), file.content);
          }
        }
        console.log(
          `ok    ${label}: ${name}, ${files.length} files${
            files.length === 0 ? ' (writes no files)' : ''
          }`,
        );
      } catch (error) {
        failures.push(label);
        console.log(`FAIL  ${label}: ${error.message.split('\n')[0]}`);
      }
    }
  } catch (error) {
    console.error(
      `Last output of the pipeline backend:\n${backendLogTail(dataDir)}`,
    );
    throw error;
  } finally {
    await backend.stop();
  }
  console.log(
    `\n${dirs.length - failures.length} of ${dirs.length} templates rendered`,
  );
  if (failures.length > 0) {
    process.exit(1);
  }
}

process.once('SIGINT', () => process.exit(130));
process.once('SIGTERM', () => process.exit(143));

try {
  await main();
} catch (error) {
  console.error(`\nTemplate check failed: ${error.message}`);
  process.exit(1);
}
