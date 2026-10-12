# resx-template

Generic ResX + ReScript starter.

Included in the base template:

- Bun server rendering with ResX
- Vite + Tailwind asset pipeline
- Bun single-file executable build path
- Page metadata, sitemap, robots, and health endpoints
- HTMX-backed server-rendered filter example
- `assets/rescript-logo.svg` wired through `ResXAssets.assets`
- `public/favicon.ico` wired through the document head
- Static content module that is easy to rename and replace

## Quick start

1. `bun install`
2. `bun run dev`
3. Open `http://localhost:9201`

The dev script does one initial ReScript compile before starting the long-running watchers so the Bun server can boot on a fresh clone.

## Useful commands

- `bun run dev`
- `bun run build`
- `bun run start`
- `bun run build:sfe`
- `bun run start:sfe`
- `bun run clean:res`

## Docker

Build and run the containerized executable:

1. `docker build -t resx-template .`
2. `docker run --rm -p 5555:5555 resx-template`

The image runs the same standalone Bun executable produced by `build:sfe`.
The page still loads HTMX from `unpkg`, so browsers opening the app need internet access to that CDN.

## Standalone executable

Build the standalone Bun single-file executable:

1. `bun run build:sfe`
2. `cd build`
3. `PORT=5557 NODE_ENV=production ./resx-template`

This follows the upstream ResX single-file executable path.

## Where to edit first

- `src/data/TemplateContent.res` for starter copy and example data
- `src/pages/` for routes
- `src/components/` for layout and reusable UI
- `src/Server.res` for route matching, health checks, and response policy
- `assets/` for transformed assets that should go through `ResXAssets.assets`
- `public/` for direct top-level files like `/favicon.ico`

## Notes

- The base branch intentionally does not include Postgres, pgtyped, migrations, or auth.
- Add database integration in a dedicated branch once the schema and deployment shape are real.
