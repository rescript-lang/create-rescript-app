# xote · CSR template

A client-only starter for [xote](https://github.com/brnrdog/xote) apps. Renders entirely in the browser, builds to a static bundle.

## Stack

- ReScript v12 (JSX transform: `XoteJSX`)
- xote ^7.2
- Vite 8
- Tailwind CSS v4 (`@tailwindcss/vite`)

## Layout

```
.
├── index.html            # mounts /src/Main.res.mjs into <div id="app">
├── vite.config.mjs       # registers @tailwindcss/vite
├── rescript.json         # JSX v4 + XoteJSX module, xote PPX, -open Xote
├── package.json
└── src/
    ├── styles.css        # @import "tailwindcss";
    ├── Counter.res       # reactive counter (@xote.component, Signal + Computed)
    ├── Page.res          # landing page composition
    └── Main.res          # imports styles, mounts <Page /> into "app"
```

## Writing components

Components use the `@xote.component` annotation, enabled by `"ppx-flags": ["xote/ppx/ppx"]` in `rescript.json`. It derives props like `@jsx.component` and makes the returned JSX fine-grained: read signals inline and only the attribute or text that reads them updates.

```rescript
@xote.component
let make = (~label: string) => {
  let count = Signal.make(0)

  <button onClick={_ => Signal.update(count, n => n + 1)}>
    {`${label}: `}
    {Signal.get(count)}
  </button>
}
```

Bare `{…}` children (strings, numbers, signal reads, nodes) render directly — no `View.text` needed. A signal read hidden behind a function from another module, or hoisted into a `let`, is read once; wrap it in a thunk (`{() => Store.total(store)}`) to keep it reactive. See the [xote docs](https://xote.dev/) for more.

The PPX ships as a prebuilt binary installed by xote's `postinstall` script. `package.json` already allows that script for pnpm (`pnpm.onlyBuiltDependencies`) and bun (`trustedDependencies`); if your package manager skipped it, run `node node_modules/xote/ppx/postinstall.js` once.

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
