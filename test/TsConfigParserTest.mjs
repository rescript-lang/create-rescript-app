import assert from "node:assert/strict";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { createRequire } from "node:module";
import { test } from "node:test";
import { parse } from "jsonc-parser";
import { read, update } from "../src/bindings/TsConfigParser.mjs";

const require = createRequire(import.meta.url);

async function fixture(t, config) {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), "cra-tsconfig-"));
  t.after(() => fs.rm(root, { recursive: true, force: true }));
  const project = path.join(root, "app");
  await fs.mkdir(path.join(project, "node_modules"), { recursive: true });
  await fs.symlink(
    path.dirname(require.resolve("typescript/package.json")),
    path.join(project, "node_modules/typescript"),
    "junction",
  );
  await fs.writeFile(path.join(project, "package.json"), '{"type":"module"}');
  await fs.writeFile(path.join(project, "index.ts"), "export {};");
  await fs.writeFile(path.join(project, "tsconfig.json"), config);
  return { root, project };
}

test("does not scan sibling packages that share the root's string prefix", async (t) => {
  const { root, project } = await fixture(
    t,
    '{"compilerOptions":{"module":"nodenext"},"include":["index.ts","../app2/*.ts"]}',
  );
  await fs.mkdir(path.join(root, "app2"));
  await fs.writeFile(
    path.join(root, "app2/package.json"),
    '{"type":"commonjs"}',
  );
  await fs.writeFile(path.join(root, "app2/external.ts"), "export {};");
  const config = read(project);
  assert.equal(config.status, "found", config.message);
  assert.equal(config.hasNestedPackageType, false);
});

test("still detects a different package type in a nested directory", async (t) => {
  const { project } = await fixture(
    t,
    '{"compilerOptions":{"module":"nodenext"}}',
  );
  await fs.mkdir(path.join(project, "nested"));
  await fs.writeFile(
    path.join(project, "nested/package.json"),
    '{"type":"commonjs"}',
  );
  await fs.writeFile(path.join(project, "nested/index.ts"), "export {};");
  const config = read(project);
  assert.equal(config.status, "found", config.message);
  assert.equal(config.hasNestedPackageType, true);
});

test("updates JSONC without removing comments, trailing commas or other options", async (t) => {
  const source =
    '{\n  // keep project settings\n  "extends": "./base.json",\n  "compilerOptions": {\n    /* keep option documentation */\n    "strict": true,\n    "allowJs": false,\n    "noEmit": true,\n  },\n}\n';
  const { project } = await fixture(t, source);
  await fs.writeFile(
    path.join(project, "base.json"),
    '{"compilerOptions":{"module":"esnext","moduleResolution":"bundler"}}',
  );
  await update(project, true, true);
  const contents = await fs.readFile(
    path.join(project, "tsconfig.json"),
    "utf8",
  );
  assert.match(contents, /keep project settings/);
  assert.match(contents, /keep option documentation/);
  assert.equal(parse(contents).extends, "./base.json");
  assert.equal(parse(contents).compilerOptions.strict, true);
  const config = read(project);
  assert.equal(config.status, "found", config.message);
  assert.equal(config.allowJs, true);
  assert.equal(config.allowImportingTsExtensions, true);
  assert.equal(config.module, "esnext");
});

test("adds missing compilerOptions and only the approved option", async (t) => {
  const { project } = await fixture(t, "{\n  // no options yet\n}\n");
  await update(project, true, false);
  const contents = await fs.readFile(
    path.join(project, "tsconfig.json"),
    "utf8",
  );
  assert.match(contents, /no options yet/);
  assert.deepEqual(parse(contents).compilerOptions, { allowJs: true });
});

test("leaves malformed configuration unchanged", async (t) => {
  const source = '{"compilerOptions": {"strict": }}';
  const { project } = await fixture(t, source);
  await assert.rejects(
    update(project, true, true),
    /Could not parse tsconfig.json/,
  );
  assert.equal(
    await fs.readFile(path.join(project, "tsconfig.json"), "utf8"),
    source,
  );
});

test("does not rewrite configuration when no changes were approved", async (t) => {
  const source = "{ /* preserve this exactly */ }";
  const { project } = await fixture(t, source);
  await update(project, false, false);
  assert.equal(
    await fs.readFile(path.join(project, "tsconfig.json"), "utf8"),
    source,
  );
});
