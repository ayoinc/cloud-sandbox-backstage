// Renders software templates with the real scaffolder, without publishing.
//
// Every template has a sample-values.json next to its template.yaml: form
// values a user could have entered. This script hands each template, its
// files and those values to the pipeline backend's dry run, which validates
// the values against the form and runs the steps that only write files. A
// template that cannot be rendered fails here instead of in front of a user.
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
import { parse } from 'yaml';
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
// Template syntax that should have been replaced by a value. GitHub Actions
// expressions such as ${{ github.sha }} are meant to survive.
const UNRENDERED = /\$\{\{\s*(values|parameters|steps|user)\b[^}]*\}\}/;

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
  let result;
  try {
    result = await backendRequest(backend, '/api/scaffolder/v2/dry-run', {
      method: 'POST',
      json: { template, values: sample.values, secrets: {}, directoryContents },
    });
  } catch (error) {
    // The scaffolder answers 400 with the schema errors of the form values.
    const invalid = error.body?.errors?.map(e => e.stack ?? e.message);
    throw invalid
      ? new Error(`The sample values were rejected: ${invalid.join('; ')}`)
      : error;
  }

  // What the steps wrote: the new repository.
  const files = result.directoryContents.map(file => ({
    path: file.path,
    content: Buffer.from(file.base64Content, 'base64'),
  }));
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
