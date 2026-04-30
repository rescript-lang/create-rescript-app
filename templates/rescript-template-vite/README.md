# ReScript / Vite Starter Template

- [Installation](../../README.md)

This is a Vite-based template with following setup:

- [ReScript](https://rescript-lang.org) with JSX v4 and [@rescript/react](https://github.com/rescript-lang/rescript-react)
- ES6 modules (ReScript code compiled to `.res.mjs` files)
- [React](https://react.dev) 19 with React DOM
- [Vite](https://vite.dev) 7 with [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react) 5
- [Tailwind CSS](https://tailwindcss.com) 4 with [@tailwindcss/vite](https://tailwindcss.com/docs/installation/using-vite)

## Development

Run ReScript in dev mode:

```sh
npm run res:dev
```

In another tab, run the Vite dev server:

```sh
npm run dev
```

## Tips

### Fast Refresh & ReScript

This template configures Vite's React plugin to process generated `.res.mjs` files and ignores `.res` / `.resi` source changes so Fast Refresh waits for ReScript's generated JavaScript output.

Make sure to create interface files (`.resi`) for each `*.res` file.

Fast Refresh requires you to **only export React components**, and it's easy to unintentionally export other values that will disable Fast Refresh (you will see a message in the browser console whenever this happens).

### Why are the generated `.res.mjs` files tracked in git?

In ReScript, it's a good habit to keep track of the actual JS output the compiler emits. It allows quick sanity checking if we made any changes that actually have an impact on the resulting JS code (especially when doing major compiler upgrades, it's a good way to verify if production code will behave the same way as before the upgrade).

This will also make it easier for your Non-ReScript coworkers to read and understand the changes in Github PRs, and call you out when you are writing inefficient code.

If you want to opt-out, feel free to remove all compiled `.res.mjs` files within the `src` directory and add `src/**/*.res.mjs` in your `.gitignore`.
