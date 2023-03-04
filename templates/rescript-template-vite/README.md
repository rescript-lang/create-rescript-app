# ReScript / Vite Starter Template

This is a Vite-based template with following setup:

- [ReScript](https://rescript-lang.org) 10.1 with @rescript/react and JSX 4 automatic mode
- ES6 modules (ReScript code compiled to `.bs.mjs` files)
- Vite 4 with React Plugin (Fast Refresh)
- Tailwind 3

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

Make sure to create interface files (`.resi`) for each `*.res` file.

Fast Refresh requires you to **only export React components**, and it's easy to unintenionally export other values that will disable Fast Refresh (you will see a message in the browser console whenever this happens).

### Why are the generated `.bs.mjs` files tracked in git?

In ReScript, it's a good habit to keep track of the actual JS output the compiler emits. It allows quick sanity checking if we made any changes that actually have an impact on the resulting JS code (especially when doing major compiler upgrades, it's a good way to verify if production code will behave the same way as before the upgrade).

This will also make it easier for your Non-ReScript coworkers to read and understand the changes in Github PRs, and call you out when you are writing inefficient code.

If you want to opt-out, feel free to remove all compiled `.mjs` files within the `src` directory and add `src/**/*.mjs` in your `.gitignore`.
