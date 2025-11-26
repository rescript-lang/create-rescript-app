# AGENTS.md

## Project Overview

`create-rescript-app` is the official CLI tool for scaffolding new ReScript applications. It supports creating projects from templates and adding ReScript to existing JavaScript projects. The tool is written in ReScript and distributed as a bundled Node.js CLI.

## Coding Style & Naming Conventions

- Make sure to use modern ReScript and not Reason syntax! Read https://rescript-lang.org/llms/manual/llm-small.txt to learn the language syntax.
- Formatting is enforced by `rescript format`; keep 2-space indentation and prefer pattern matching over chained conditionals.
- Module files are PascalCase (`Templates.res`), values/functions camelCase, types/variants PascalCase, and records snake_case fields only when matching external JSON.
- Keep `.resi` signatures accurate and minimal; avoid exposing helpers that are template-specific.
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
- **`npm run format`** - Apply ReScript formatter across all source files

## Testing and Validation

- **Manual Testing**: No automated test suite - perform smoke tests by running the CLI into a temp directory
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
