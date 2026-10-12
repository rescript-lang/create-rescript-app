import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import {
  appendFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync,
  readdirSync, rmSync, writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { basename, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";

const managers = {
  npm: { command: "npm", lockfile: "package-lock.json" },
  pnpm: { command: "pnpm", lockfile: "pnpm-lock.yaml" },
  "yarn-classic": { command: "yarn", lockfile: "yarn.lock" },
  "yarn-berry": { command: "yarn", lockfile: "yarn.lock" },
  bun: { command: "bun", lockfile: "bun.lock" },
};

const read = path => readFileSync(path, "utf8");
const readJson = path => JSON.parse(read(path));
const writeJson = (path, value) => writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`);
const shellQuote = value => `'${value.replaceAll("'", "'\\''")}'`;
const shellJoin = command => command.map(shellQuote).join(" ");

class Suite {
  constructor(options, workspace) {
    this.manager = options.manager;
    Object.assign(this, managers[this.manager]);
    this.workspace = workspace;
    this.logs = resolve(options.logs);
    this.package = resolve(options.package);
    mkdirSync(this.logs, { recursive: true });
    this.log = join(this.logs, "setup.log");
    this.env = {
      ...process.env,
      // Exercise normal project detection and prompts, bypassing the old CI-only path.
      CI: "false",
      TERM: "xterm",
      NO_COLOR: "1",
      NPM_CONFIG_AUDIT: "false",
      NPM_CONFIG_FUND: "false",
      YARN_ENABLE_TELEMETRY: "0",
    };
    delete this.env.FORCE_COLOR;
    this.passed = 0;
  }

  async setup() {
    await this.run(["node", "--version"], this.workspace);
    await this.run([this.command, "--version"], this.workspace);
    const cliDirectory = join(this.workspace, "cli");
    await this.run(["npm", "install", "--prefix", cliDirectory, this.package], this.workspace);
    this.env.CRA_E2E_CLI = join(cliDirectory, "node_modules/create-rescript-app/out/create-rescript-app.cjs");
    this.launcher = join(this.workspace, "launcher");
    mkdirSync(this.launcher);
    const wrapper = fileURLToPath(new URL("./launch-cli.mjs", import.meta.url));
    writeJson(join(this.launcher, "package.json"), {
      name: "cra-e2e-launcher",
      private: true,
      scripts: { cra: shellJoin(["node", wrapper]) },
    });
    if (this.manager === "yarn-berry") {
      writeFileSync(join(this.launcher, ".yarnrc.yml"), "nodeLinker: node-modules\n");
    }
    await this.run([this.command, "install"], this.launcher);
  }

  async run(command, cwd, { expected = 0, terminal = false, prompts = [] } = {}) {
    appendFileSync(this.log, `\n$ ${shellJoin(command)}\n(cwd: ${cwd})\n`);
    // Ubuntu's util-linux script allocates a real terminal for the interactive CLI.
    // Node handles process control, prompt answers and assertions without native addons.
    const invocation = terminal
      ? ["script", "--quiet", "--return", "--echo=never", "--command",
          `stty cols 160 rows 40; exec ${shellJoin(command)}`, "/dev/null"]
      : command;
    const child = spawn(invocation[0], invocation.slice(1), {
      cwd,
      env: this.env,
      detached: true,
      stdio: [terminal ? "pipe" : "ignore", "pipe", "pipe"],
    });
    let output = "";
    let pending = "";
    let nextPrompt = 0;
    let timedOut = false;
    let inputError;
    let forceKill;
    const killGroup = signal => {
      try {
        process.kill(-child.pid, signal);
      } catch (error) {
        if (error.code !== "ESRCH") throw error;
      }
    };
    const timeout = setTimeout(() => {
      timedOut = true;
      killGroup("SIGTERM");
      forceKill = setTimeout(() => killGroup("SIGKILL"), 3000);
    }, 300_000);
    const collect = chunk => {
      output += chunk;
      appendFileSync(this.log, chunk);
      pending += chunk;
      if (nextPrompt < prompts.length) {
        const [question, answer] = prompts[nextPrompt];
        if (pending.includes(question)) {
          child.stdin.write(answer);
          nextPrompt += 1;
          pending = "";
        }
      }
    };
    child.stdout.setEncoding("utf8").on("data", collect);
    child.stderr.setEncoding("utf8").on("data", collect);
    // The terminal may close immediately after its last answer is written.
    child.stdin?.on("error", error => {
      if (error.code !== "EPIPE") {
        inputError = error;
        killGroup("SIGTERM");
      }
    });
    try {
      const [code, signal] = await new Promise((resolve, reject) => {
        child.once("error", reject);
        child.once("close", (code, signal) => resolve([code, signal]));
      });
      if (inputError) throw inputError;
      assert(!timedOut, `Command timed out: ${shellJoin(command)}`);
      assert.equal(code, expected, `Command exited ${code ?? signal}, expected ${expected}: ${shellJoin(command)}`);
      assert.equal(nextPrompt, prompts.length, "CLI exited before answering all prompts");
      return output;
    } finally {
      clearTimeout(timeout);
      clearTimeout(forceKill);
      child.stdin?.destroy();
    }
  }

  async cli(cwd, args = [], options = {}) {
    // Package scripts supply the manager's actual npm_execpath/user agent.
    const separator = this.manager === "npm" ? ["--"] : [];
    return this.run([this.command, "run", "cra", ...separator, cwd, ...args], this.launcher, {
      ...options,
      terminal: true,
    });
  }

  async case(name, perform) {
    this.log = join(this.logs, `${name}.log`);
    writeFileSync(this.log, "");
    const directory = join(this.workspace, name);
    mkdirSync(directory);
    console.log(`RUN ${this.manager}: ${name}`);
    await perform(directory);
    this.passed += 1;
    console.log(`PASS ${this.manager}: ${name}`);
  }

  async verifyProject(directory, suffix) {
    const packageJson = readJson(join(directory, "package.json"));
    const config = readJson(join(directory, "rescript.json"));
    assert.equal(config.name, packageJson.name, "Project and package names differ");
    assert.equal(config.suffix, suffix, "Unexpected generated JS suffix");
    assert(existsSync(join(directory, this.lockfile)), `Missing ${this.lockfile}: manager detection failed`);
    if (this.manager !== "npm") {
      assert(!existsSync(join(directory, "package-lock.json")), "npm lockfile was not removed");
    }
    if (this.manager === "yarn-berry") {
      assert(read(join(directory, ".yarnrc.yml")).includes("nodeLinker: node-modules"),
        "Yarn Berry node-modules linker was not configured");
    }
    const { version } = readJson(join(directory, "node_modules/rescript/package.json"));
    assert(version.startsWith("12."), `Expected a current ReScript 12 version, installed ${version}`);
    assert(!Object.hasOwn(packageJson.dependencies ?? {}, "@rescript/core"),
      "ReScript 12 should use its bundled standard library");
    await this.run([this.command, "run", "res:build"], directory);
    const output = await this.run(["node", `src/Demo${suffix}`], directory);
    assert.equal(output.trim(), "Hello, world!", "Unexpected generated program output");
  }

  verifyPreserved(directory, preserved) {
    for (const [path, contents] of Object.entries(preserved)) {
      const actual = read(join(directory, path));
      if (path === ".gitignore") {
        assert(actual.startsWith(contents), `Overwrote ${path}`);
      } else {
        assert.equal(actual, contents, `Overwrote ${path}`);
      }
    }
  }

  async newProject(directory, { target = "my-app", devcontainer = false } = {}) {
    const currentDirectory = target === "." || target === "./";
    const project = currentDirectory ? directory : join(directory, target);
    const preserved = {};
    if (devcontainer) {
      mkdirSync(join(project, ".devcontainer"), { recursive: true });
      preserved[".devcontainer/devcontainer.json"] = '{"name":"keep me"}\n';
      if (currentDirectory) {
        Object.assign(preserved, { "README.md": "Existing README\n", ".gitignore": "keep-this-entry\n" });
      }
      for (const [path, contents] of Object.entries(preserved)) writeFileSync(join(project, path), contents);
    }
    await this.cli(directory, [target, "--template", "basic"]);
    assert.equal(readJson(join(project, "package.json")).name, basename(project),
      "Current-directory package name was not derived from the directory");
    this.verifyPreserved(project, preserved);
    await this.verifyProject(project, ".res.mjs");
  }

  async existingProject(directory, { module = "commonjs", typescript } = {}) {
    const original = {
      name: basename(directory),
      version: "1.0.0",
      private: true,
      type: module,
      scripts: { test: "node src/original.cjs" },
      dependencies: { "is-number": "7.0.0" },
    };
    if (typescript) original.devDependencies = { typescript: "5.9.3" };
    writeJson(join(directory, "package.json"), original);
    mkdirSync(join(directory, "src"));
    const preserved = {
      "README.md": "Existing project README\n",
      ".gitignore": "existing-ignore\n",
      "src/original.cjs": 'console.log(require("is-number")(42));\n',
    };
    if (typescript) {
      preserved["src/original.ts"] = "export const existingValue: number = 1;\n";
      preserved["tsconfig.base.json"] = JSON.stringify({ compilerOptions: {
        module: typescript === "nodenext" ? "NodeNext" : "ESNext",
        moduleResolution: typescript,
        target: "ES2022", strict: true, noEmit: true,
      } }, null, 2);
      writeFileSync(join(directory, "tsconfig.json"), `{
  // Preserve this comment and the inherited configuration.
  "extends": "./tsconfig.base.json",
  "compilerOptions": {"skipLibCheck": true,},
  "include": ["src"],
}
`);
    }
    for (const [path, contents] of Object.entries(preserved)) writeFileSync(join(directory, path), contents);
    await this.run([this.command, "install"], directory);
    const prompts = [
      ["Do you want to add ReScript", "y"],
      ["ReScript version?", "\r"],
      ["Where will you put your ReScript source files?", "\r"],
    ];
    if (typescript) {
      prompts.push(["Set compilerOptions.allowJs to true", "y"]);
      if (typescript === "bundler") {
        prompts.push(["Set compilerOptions.allowImportingTsExtensions to true", "y"]);
      }
    } else {
      prompts.push(["What module system will you use?", module === "module" ? "\r" : "\x1b[B\r"]);
    }
    prompts.push(["Do you want to check generated", "n"]);
    await this.cli(directory, [], { prompts });
    const packageJson = readJson(join(directory, "package.json"));
    for (const field of ["name", "version", "private", "type"]) {
      assert.equal(packageJson[field], original[field], `Changed existing package field ${field}`);
    }
    assert.equal(packageJson.scripts.test, original.scripts.test, "Overwrote existing script");
    assert.equal(packageJson.dependencies["is-number"], "7.0.0", "Changed existing dependency");
    if (typescript) assert.deepEqual(packageJson.devDependencies, original.devDependencies, "Changed TypeScript dependency");
    this.verifyPreserved(directory, preserved);
    const suffix = typescript || module === "commonjs" ? ".res.js" : ".res.mjs";
    assert(read(join(directory, ".gitignore")).includes(`**/*${suffix}`), "Generated JS was not ignored");
    if (typescript) {
      const config = readJson(join(directory, "rescript.json"));
      assert.equal(config.gentypeconfig.moduleResolution,
        typescript === "nodenext" ? "node16" : "bundler", "Incorrect genType mapping");
      const tsconfig = read(join(directory, "tsconfig.json"));
      assert(tsconfig.includes("// Preserve this comment"), "Lost tsconfig comment");
      assert(tsconfig.includes('"allowJs": true'), "Did not enable allowJs");
      if (typescript === "bundler") {
        assert(tsconfig.includes('"allowImportingTsExtensions": true'), "Did not enable TS extension imports");
      }
      writeFileSync(join(directory, "src/Interop.res"), "@genType\nlet answer = 42\n");
      const extension = typescript === "bundler" ? "ts" : "js";
      writeFileSync(join(directory, "src/consumer.ts"),
        `import {answer} from "./Interop.gen.${extension}";\nconst value: number = answer;\n`);
    }
    await this.verifyProject(directory, suffix);
    const output = await this.run([this.command, "run", "test"], directory);
    assert(output.split(/\r?\n/).includes("true"), "Existing JavaScript program no longer runs");
    if (typescript) {
      assert(existsSync(join(directory, "src/Interop.gen.ts")), "genType did not generate TypeScript");
      await this.run(["node", "node_modules/typescript/bin/tsc", "--noEmit"], directory);
    }
  }

  async occupiedDirectory(directory) {
    const project = join(directory, "occupied");
    mkdirSync(project);
    const sentinel = join(project, "keep.txt");
    writeFileSync(sentinel, "Do not overwrite\n");
    await this.cli(directory, ["occupied", "--template", "basic"], { expected: 1 });
    assert.equal(read(sentinel), "Do not overwrite\n", "Overwrote occupied directory");
    assert.deepEqual(readdirSync(project), ["keep.txt"], "Failed scaffolding left files in the occupied directory");
  }

  async execute() {
    await this.case("new-basic", path => this.newProject(path));
    await this.case("existing-commonjs", path => this.existingProject(path));
    if (this.manager === "npm") {
      await this.case("existing-esm", path => this.existingProject(path, { module: "module" }));
      for (const typescript of ["nodenext", "bundler"]) {
        await this.case(`existing-ts-${typescript}`, path => this.existingProject(path, { module: "module", typescript }));
      }
      for (const [name, target] of [["devcontainer-named", "my-app"], ["devcontainer-dot", "."],
          ["devcontainer-dot-slash", "./"]]) {
        await this.case(name, path => this.newProject(path, { target, devcontainer: true }));
      }
      await this.case("occupied-directory", path => this.occupiedDirectory(path));
    }
    console.log(`PASS: ${this.passed} E2E cases for ${this.manager}`);
  }
}

const { values } = parseArgs({ options: {
  package: { type: "string" }, manager: { type: "string" }, logs: { type: "string" },
} });
assert.equal(process.platform, "linux", "The E2E terminal runner requires Linux with util-linux script");
assert(values.package && values.logs && Object.hasOwn(managers, values.manager),
  `Usage: npm run test:e2e -- --package <tarball> --manager <${Object.keys(managers).join("|")}> --logs <directory>`);

const workspace = mkdtempSync(join(tmpdir(), "cra e2e "));
const suite = new Suite(values, workspace);
try {
  await suite.setup();
  await suite.execute();
} catch (error) {
  if (existsSync(suite.log)) console.error(read(suite.log));
  console.error(`FAIL ${suite.manager}; log: ${suite.log}`);
  console.error(error);
  process.exitCode = 1;
} finally {
  rmSync(workspace, { recursive: true, force: true });
}
