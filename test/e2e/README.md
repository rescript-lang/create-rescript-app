# Installation E2E tests

The `e2e` job in `.github/workflows/ci.yml` tests the CLI tarball produced by the
build job on Ubuntu with Node 20.19.0, the minimum supported version.

Each package manager (npm, pnpm, Yarn Classic, Yarn Berry, Bun) creates a basic
project and adds ReScript to an existing CommonJS project using the current
ReScript 12 release. Both projects install real dependencies, compile
ReScript and execute the generated program. Existing scripts, dependencies and
source files must survive, and the expected package manager lockfile must exist.

The npm job also covers existing ESM projects, NodeNext and bundler TypeScript
projects (including compiling a genType consumer), devcontainer-only directories,
`.` and `./`, and rejection of an occupied target without modifying its files.

The harness is written in ReScript, alongside the other tests. `E2eScenarios.res`
contains the fixtures and assertions, `E2eProcess.res` runs commands and answers
prompts, and Node bindings live in `src/bindings/Node.res`. `E2eLaunch.res` runs the
packed CLI through the selected manager's package script. The `test/` source
directory is already included in `rescript.json`.

The harness uses Node.js built-ins and Ubuntu's `script` utility (from util-linux)
to answer the real interactive prompts through a pseudo-terminal. It sets
`CI=false` for the CLI so the old hardcoded CI
smoke-test path cannot bypass the scenario being tested. A launcher package script
supplies the chosen manager's actual environment for package-manager detection.
Each case uses an isolated temporary directory, including spaces in its path.
Commands have timeouts, and failed CI jobs upload terminal and command logs.

To reproduce a matrix entry on Linux with Node, util-linux and the chosen
package manager installed:

```sh
npm pack
npm run test:e2e -- --package create-rescript-app-1.12.1.tgz --manager npm --logs /tmp/cra-e2e-logs
```

The terminal runner currently targets Linux, matching CI. The other package-manager names are
`pnpm`, `yarn-classic`, `yarn-berry` and `bun`; install the pinned version from the
workflow when reproducing a particular job.

`npm run test:e2e` compiles the ReScript sources before running the harness.
Run `npm ci` first to install its build dependencies. Generated `.res.mjs` files
are not committed.
