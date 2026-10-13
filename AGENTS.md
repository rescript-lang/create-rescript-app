# AGENTS.md

## Project Overview

`create-rescript-app` is the official CLI tool for scaffolding new ReScript applications. It supports creating projects from templates and adding ReScript to existing JavaScript projects. The tool is written in ReScript and distributed as a bundled Node.js CLI.

## Coding Style & Naming Conventions

- Use ReScript 12 syntax and the built-in standard library, not Reason syntax. Read https://rescript-lang.org/llms/manual/llm-small.txt to learn the language syntax.
- Prefer `Option`, `Result`, `Array`, `List`, `Dict`, `Set`, `Map`, and `JSON` over `Js.*` or `Belt.*`.
- Match local style; avoid old BuckleScript/ReScript-era patterns.
- Write new tests and test helpers in ReScript under `test/`. Prefer records and functions over classes.
- Keep parameters mandatory unless callers need to omit them.
- Do not add redundant parentheses around switch expressions: use `switch value { ... }`. Parentheses required by tuple syntax are fine.
- Formatting is enforced by `rescript format`; keep 2-space indentation and prefer pattern matching over chained conditionals.
- Separate multiline `let` bindings (including `let?`) and type definitions from surrounding statements or declarations with a blank line before and after. Keep attached comments and attributes together with the declaration.
- Prefer `result` values over exceptions for expected failure paths; only raise or throw at clear integration boundaries where the surrounding API requires it.
- Use `let?` to unwrap and propagate `Option`/`Result` failures where it simplifies the code. `LetUnwrap` is enabled in `rescript.json`.
- Prefer pattern matching over `if`/`else` chains when branching on the shape or state of the same value; plain comparisons across different values are fine with `if`/`else`.
- Do not run `rescript`, `npm test`, or `npm run prepack` in parallel; ReScript compiler artifacts are not safe for concurrent builds in this repo.
- Module files and variant constructors are PascalCase (`Templates.res`), values/functions and type names camelCase, and records use snake_case fields only when matching external JSON.
- Keep `.resi` signatures accurate and minimal; avoid exposing helpers that are template-specific.
- Keep Node.js bindings in `src/bindings/Node.res` and reuse existing bindings.
- When touching templates, mirror upstream defaults and keep package scripts consistent with the chosen toolchain.

## Package Manager Support

- Detects and supports npm, yarn, pnpm, and bun
- Handles existing project detection based on presence of `package.json`
- Adapts installation commands based on detected package manager

## Directory Structure

- **`src/`**: ReScript source files
- **`lib/`**: Generated build artifacts from ReScript compiler (do not edit)
- **`out/`**: Production bundle (`create-rescript-app.cjs`) for distribution
- **`templates/`**: Project starter templates (keep self-contained)
- **`bindings/`**: External library bindings (ClackPrompts, CompareVersions)

## Development Commands

- **`npm start`** - Run CLI directly from source (`src/Main.res.mjs`) for interactive testing and development
- **`npm run dev`** - Watch ReScript sources and rebuild automatically to `lib/` directory
- **`npm run prepack`** - Compile ReScript and bundle with Rollup into `out/create-rescript-app.cjs` (production build)
- **`npm test`** - Compile ReScript sources and run the Node.js regression tests
- **`npm run format`** - Apply ReScript formatter across all source files

## Testing and Validation

- **Automated Tests**: Run `npm test` for automated coverage of CLI parsing and related helpers
- **Installation E2E**: Run `npm pack`, then `npm run test:e2e -- --package <tarball> --manager <manager> --logs <directory>`. Requires Linux, util-linux `script`, and the selected package manager; use the versions in `.github/workflows/ci.yml`.
- **Manual Testing**: Perform smoke tests by running the CLI into a temp directory
- **CI Preview Testing**: To test a pkg.pr.new build from CI, run `npm exec --yes --package=https://pkg.pr.new/rescript-lang/create-rescript-app/create-rescript-app@<commit> -- create-rescript-app my-app --template vite` and replace `<commit>` with the SHA from the pkg.pr.new CI comment.
- **Template Validation**: After changes, test each template type (basic/Next.js/Vite) to ensure templates bootstrap cleanly
- **Build Verification**: Run `npm run prepack` to ensure the production bundle builds correctly

## Build System

- **ReScript Compiler**: Outputs ES modules in-source (`src/*.res.mjs`) with configuration in `rescript.json`
- **Rollup Bundler**: Creates `out/create-rescript-app.cjs` CommonJS bundle for distribution

## Template Modification Guidelines

When modifying templates:

1. Maintain consistency with upstream toolchain defaults
2. Ensure package scripts match the chosen build tool (Vite, Next.js, etc.)
3. Keep templates self-contained with their own dependencies
4. Test template bootstrapping after modifications
