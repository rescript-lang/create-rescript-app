# genType tsconfig Mapping Rules

This note defines the rules for issue #44: when adding ReScript to an
existing TypeScript project, infer the ReScript and genType configuration from
the project's effective `tsconfig.json` instead of asking the user to choose a
module system manually.

## Research Summary

- ReScript v12 genType is configured through top-level `gentypeconfig` in
  `rescript.json`.
- genType supports `gentypeconfig.module` values `esmodule` and `commonjs`.
- genType supports `gentypeconfig.moduleResolution` values `node`, `node16`,
  and `bundler`.
- ReScript's TypeScript integration currently requires `"in-source": true` and
  generated JS suffixes ending in `.js`, for example `.res.js`.
- ReScript's TypeScript integration requires TypeScript `allowJs: true`.
- ReScript's `bundler` genType mode requires TypeScript 5.0+ and
  `allowImportingTsExtensions: true`.
- TypeScript `allowImportingTsExtensions` is only valid when `noEmit` or
  `emitDeclarationOnly` is enabled.
- TypeScript `node16`, `node18`, `node20`, and `nodenext` module modes can emit
  CommonJS or ESM per file. For `.ts` and `.tsx` files, package.json `"type"`
  decides the format: `"module"` means ESM, otherwise CommonJS.
- TypeScript `moduleResolution: "bundler"` models bundlers and does not require
  file extensions on relative imports.

## Effective Input

Read the effective TypeScript configuration, not only the raw root
`tsconfig.json`.

1. Find `tsconfig.json` in the current project root.
2. Resolve `extends` using TypeScript semantics before mapping values.
3. Preserve the root project's `package.json` context.
4. Read at least these fields:
   - `compilerOptions.module`
   - `compilerOptions.moduleResolution`
   - `compilerOptions.allowJs`
   - `compilerOptions.allowImportingTsExtensions`
   - `compilerOptions.noEmit`
   - `compilerOptions.emitDeclarationOnly`
   - `compilerOptions.jsx`
   - package.json `type`

Use a JSONC-aware parser or TypeScript's own config parser when implementing
this. `tsconfig.json` can contain comments, trailing commas, and inherited
settings.

If there is no `tsconfig.json`, or the effective config cannot be read, keep the
current manual module prompt.

## ReScript Output Baseline

When genType is enabled for an existing TypeScript project, set:

```json
{
  "package-specs": {
    "module": "<mapped module>",
    "in-source": true
  },
  "suffix": ".res.js",
  "gentypeconfig": {
    "module": "<mapped module>",
    "moduleResolution": "<mapped module resolution>",
    "generatedFileExtension": "<mapped generated file extension>"
  }
}
```

Use `.res.js` for both ESM and CommonJS genType setups. The current CLI behavior
of using `.res.mjs` for ESM is fine for plain ReScript output, but it conflicts
with the documented genType limitation that TypeScript integration currently
supports suffixes ending in `.js`.

The mapped `gentypeconfig.module` should match `package-specs.module`.

## Module Format Mapping

Normalize `compilerOptions.module` and `package.json.type` to lowercase before
mapping.

| TypeScript input | package.json `type` | ReScript `package-specs.module` | genType `module` | Notes |
| --- | --- | --- | --- | --- |
| `commonjs` | any | `commonjs` | `commonjs` | Straight CommonJS mapping. |
| `es2015`, `es6`, `es2020`, `es2022`, `esnext` | any | `esmodule` | `esmodule` | Runtime-agnostic ESM output. |
| `preserve` | any | `esmodule` | `esmodule` | Best fit for bundlers. Warn if the project relies on statement-level CommonJS preservation. |
| `node16`, `node18`, `node20`, `nodenext` | `module` | `esmodule` | `esmodule` | `.ts` and `.tsx` files emit as ESM in this package scope. |
| `node16`, `node18`, `node20`, `nodenext` | absent or `commonjs` | `commonjs` | `commonjs` | `.ts` and `.tsx` files emit as CommonJS in this package scope. |
| `amd`, `umd`, `system`, `none` | any | none | none | Unsupported by ReScript's two genType module formats. Fall back to manual prompt or abort genType setup. |
| missing or unknown | any | none | none | Do not guess. Fall back to the current manual prompt. |

For Node dual-format projects, warn when the project contains `.mts` or `.cts`
files, or package subdirectories with their own package.json `type`. ReScript
has one project-level module output setting, so it cannot exactly mirror a mixed
per-file TypeScript module graph.

## Module Resolution Mapping

Normalize `compilerOptions.moduleResolution` to lowercase. If it is missing,
infer the effective TypeScript default only when the `module` setting makes the
default unambiguous.

| Effective TypeScript module resolution | genType `moduleResolution` | Notes |
| --- | --- | --- |
| `bundler` | `bundler` | Also requires `allowImportingTsExtensions: true`. |
| `node16` | `node16` | Exact documented genType mapping. |
| `nodenext` | `node16` | ReScript v12 documents NodeNext as a use case but only exposes `node16`; warn that this is an approximation. |
| `node`, `node10` | `node` | Legacy Node/CommonJS resolver. |
| `classic` | none | Unsupported for genType setup. Fall back to manual prompt or abort genType setup. |
| missing with `module: "preserve"` | `bundler` | TypeScript uses bundler-style resolution for preserve-mode bundled projects. |
| missing with `module: "node16"`, `node18`, `node20`, or `nodenext` | `node16` | Use the Node ESM-compatible genType mode. Warn for `nodenext` as above. |
| missing with `commonjs` | `node` | Legacy CommonJS default. |
| missing with ESM-family module values | none | Do not invent `node`; use TypeScript's effective value if the parser provides one, otherwise prompt. |
| unknown | none | Do not guess. Fall back to manual prompt. |

## TypeScript Config Edits And Warnings

### `allowJs`

If `compilerOptions.allowJs` is not `true`, warn and offer to set it to `true`.
ReScript's TypeScript integration requires this so TypeScript can accept the JS
files emitted by ReScript and imported by generated genType files.

### `allowImportingTsExtensions`

If the mapped genType module resolution is `bundler`:

1. If `allowImportingTsExtensions` is already `true`, no action is needed.
2. If `noEmit: true` or `emitDeclarationOnly: true`, offer to set
   `allowImportingTsExtensions: true`.
3. Otherwise, warn that TypeScript does not allow
   `allowImportingTsExtensions` unless `noEmit` or `emitDeclarationOnly` is
   enabled. Continue only after confirmation, or fall back to manual setup.

### Generated File Extension

Use:

| Signal | `gentypeconfig.generatedFileExtension` |
| --- | --- |
| `compilerOptions.jsx` is present | `.gen.tsx` |
| React, Next.js, or another JSX framework is detected in package.json dependencies | `.gen.tsx` |
| No JSX signal | `.gen.ts` |

Set `.gen.ts` explicitly when no JSX signal is available. That differs from the
documented genType default of `.gen.tsx`, but it is less surprising for existing
non-React TypeScript projects.

## Fallback Rules

Fall back to the current manual module prompt when:

- There is no readable `tsconfig.json`.
- The effective TypeScript config cannot be resolved.
- `module` is missing or unsupported.
- `moduleResolution` is `classic`, unknown, or conflicts with the module mode.
- The project is a mixed Node dual-format project that cannot be represented by
  one ReScript project-level module setting, such as a CommonJS package with
  `.mts` inputs, an ESM package with `.cts` inputs, or included source files
  under nested package.json files with a different `type`.
- The project uses `module: "preserve"` and package contents suggest meaningful
  CommonJS-style exports that ReScript cannot preserve statement-by-statement.

When falling back, still surface the detected values in the prompt so the user
can make an informed choice.

## Implementation Notes

- Prefer loading the target project's `typescript` package and using its config
  parser when available. That handles JSONC and `extends` correctly.
- If TypeScript is not available yet, use a JSONC parser and implement only the
  documented `extends` behavior needed for `compilerOptions`, or ask the user to
  install dependencies first.
- Do not copy the existing Next.js template's legacy `gentypeconfig` shape
  (`language`, `shims`) into the add-to-existing flow. The v12 manual documents
  the current compiler-integrated fields used above.
- Keep generated JS ignore behavior tied to the selected suffix. For genType,
  the suffix is always `.res.js`, so the gitignore prompt should refer to
  generated `.res.js` files.

## Sources

- ReScript build configuration, especially `package-specs`, `suffix`, and
  `gentypeconfig`: https://rescript-lang.org/docs/manual/build-configuration/
- ReScript TypeScript integration setup, `allowJs`, module resolution, and
  genType limitations: https://rescript-lang.org/docs/manual/typescript-integration/
- TypeScript `module` option and Node dual-format behavior:
  https://www.typescriptlang.org/tsconfig/module.html
- TypeScript module resolution reference:
  https://www.typescriptlang.org/tsconfig/moduleResolution.html
- TypeScript module reference for Node and bundler resolution:
  https://www.typescriptlang.org/docs/handbook/modules/reference.html
- TypeScript `allowImportingTsExtensions` constraints:
  https://www.typescriptlang.org/tsconfig/allowImportingTsExtensions.html
- TypeScript `extends` behavior:
  https://www.typescriptlang.org/tsconfig/extends.html
