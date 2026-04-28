# xote · CSR template

A client-only starter for [xote](https://github.com/brnrdog/xote) apps. Renders entirely in the browser, builds to a static bundle.

## Stack

- ReScript v12 (JSX transform: `XoteJSX`)
- xote ^6.2 + rescript-signals
- Vite 7
- Tailwind CSS v4 (`@tailwindcss/vite`)

## Layout

```
.
├── index.html            # mounts /src/Main.res.mjs into <div id="app">
├── vite.config.mjs       # registers @tailwindcss/vite
├── rescript.json         # JSX v4 + XoteJSX module, -open Xote
├── package.json
└── src/
    ├── styles.css        # @import "tailwindcss";
    ├── Counter.res       # reactive counter (Signal-based)
    ├── Page.res          # landing page composition
    └── Main.res          # imports styles, mounts <Page /> into "app"
```

## Scripts

| Script | What it does |
| --- | --- |
| `npm run res:dev` | Watches and compiles ReScript on save. Run in its own terminal during development. |
| `npm run res:build` | One-shot ReScript build. |
| `npm run res:clean` | Removes ReScript build artifacts. |
| `npm run dev` | Starts the Vite dev server. |
| `npm run build` | Produces a production bundle in `dist/`. |
| `npm run preview` | Serves the production bundle locally. |

## Develop

Run the ReScript watcher and Vite together (two terminals):

```bash
npm install
npm run res:dev
# in another terminal:
npm run dev
```

ReScript compiles `*.res` files into `*.res.mjs` next to them (`in-source: true`). Vite picks up those generated modules directly.

## Build

```bash
npm run res:build
npm run build
```

The resulting `dist/` directory is fully static — host it on any CDN or static file server.
