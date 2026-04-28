# xote · SSR template

A server-rendered starter for [xote](https://github.com/brnrdog/xote) apps. Renders HTML on a Node server, then hydrates on the client so reactivity takes over without re-rendering.

## Stack

- ReScript v12 (JSX transform: `XoteJSX`)
- xote ^6.2 — uses `SSR.renderToString`, `SSRState`, and `Hydration`
- rescript-signals
- Vite 7 — runs in middleware mode for dev, and produces both client and SSR bundles for production
- Tailwind CSS v4 (`@tailwindcss/vite`)

## Layout

```
.
├── index.html            # template with <!--app-html--> and <!--app-state--> placeholders
├── server.mjs            # Node HTTP server (Vite middleware in dev, static + SSR in prod)
├── vite.config.mjs
├── rescript.json
├── package.json
└── src/
    ├── styles.css
    ├── Counter.res       # uses SSRState.signal so state survives hydration
    ├── Page.res          # landing page composition
    ├── App.res           # shared `view` thunk used by server and client
    ├── Server.res        # exports render() → { html, stateScript }
    └── Client.res        # imports styles, calls Hydration.hydrateById
```

## How it fits together

1. `server.mjs` reads `index.html` and (in dev) hands it to Vite for asset/CSS transformation.
2. It imports `Server.res` and calls `render()`, which uses `SSR.renderToString(App.view)` to produce HTML and `SSRState.generateScript()` to produce a `<script>` tag carrying initial signal values.
3. The placeholders `<!--app-html-->` and `<!--app-state-->` in `index.html` are replaced with those two strings.
4. The browser loads `Client.res.mjs`, which calls `Hydration.hydrateById(App.view, "root")`. xote walks the existing DOM, attaches reactive bindings, and reads back the serialized `SSRState` so signals start with the same values the server used.

## Scripts

| Script | What it does |
| --- | --- |
| `npm run res:dev` | Watches and compiles ReScript on save. Run during development. |
| `npm run res:build` | One-shot ReScript build. |
| `npm run res:clean` | Removes ReScript build artifacts. |
| `npm run dev` | Runs `node server.mjs` with Vite in middleware mode. |
| `npm run build` | Builds the client bundle and the SSR bundle. |
| `npm run build:client` | Just the client bundle (`dist/client/`). |
| `npm run build:ssr` | Just the SSR bundle (`dist/server/Server.res.js`). |
| `npm run start` | Runs the server in production mode against the built bundles. |

## Develop

```bash
npm install
npm run res:dev
# in another terminal:
npm run dev
```

Open http://localhost:3000. The page is server-rendered (view source — the counter HTML is already there) and becomes interactive after hydration.

## Build & run in production

```bash
npm run res:build
npm run build
npm run start
```

`server.mjs` defaults to port 3000; override with `PORT=8080 npm run start`.
