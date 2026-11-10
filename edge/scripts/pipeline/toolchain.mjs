// Prints the TechDocs tool versions the root Dockerfile pins. The portal-sync
// workflow installs exactly these, so documentation is built with the same
// tools in both places and the versions are written down once.
//
//   node toolchain.mjs pip   the mkdocs packages, as arguments for pip install
//   node toolchain.mjs d2    the D2 release, e.g. v0.9.0
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { repoRoot } from './settings.mjs';

const dockerfile = readFileSync(join(repoRoot, 'Dockerfile'), 'utf8');
const found = {
  pip: dockerfile.match(/\bmkdocs-[a-z0-9-]+==[0-9][0-9a-z.]*/g)?.join(' '),
  d2: dockerfile.match(/^FROM terrastruct\/d2:(v[0-9][0-9a-z.]*)/m)?.[1],
};
const value = found[process.argv[2]];
if (!value) {
  console.error(
    `Usage: toolchain.mjs pip|d2. Nothing found for "${process.argv[2]}" in the Dockerfile.`,
  );
  process.exit(1);
}
console.log(value);
