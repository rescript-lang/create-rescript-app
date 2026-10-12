# Installation E2E tests

The `e2e` job in `.github/workflows/ci.yml` tests the CLI tarball produced by the
build job on Ubuntu with Node 20.19.0, the minimum supported version.

Each package manager (npm, pnpm, Yarn Classic, Yarn Berry, Bun) creates a basic
project with the current ReScript 12 default and adds ReScript 11.1.4 to an
existing CommonJS project. Both projects install real dependencies, compile
ReScript and execute the generated program. Existing scripts, dependencies and
source files must survive, and the expected package manager lockfile must exist.

The npm job also covers existing ESM projects, NodeNext and bundler TypeScript
projects (including compiling a genType consumer), devcontainer-only directories,
`.` and `./`, and rejection of an occupied target without modifying its files.

The harness uses Python's standard-library pseudo-terminal support to answer the
real interactive prompts. It sets `CI=false` for the CLI so the old hardcoded CI
smoke-test path cannot bypass the scenario being tested. A launcher package script
supplies the chosen manager's actual environment for package-manager detection.
Each case uses an isolated temporary directory, including spaces in its path.
Commands have timeouts, and failed CI jobs upload terminal and command logs.

To reproduce a matrix entry on a POSIX host with Python 3, Node and the chosen
package manager installed:

```sh
npm pack
python3 test/e2e/run.py --package create-rescript-app-1.12.1.tgz --manager npm --logs /tmp/cra-e2e-logs
```

The suite runs on the host operating system. CI provides Linux coverage; running
it directly on macOS provides macOS coverage. The other package-manager names are
`pnpm`, `yarn-classic`, `yarn-berry` and `bun`; install the pinned version from the
workflow when reproducing a particular job.
