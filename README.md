# create-rescript-app

Quickly create new [ReScript](https://rescript-lang.org/) apps from project templates:

```sh
npm create rescript-app@latest
```

(note: `@latest` is important, otherwise npm may run an old version) or

```sh
yarn create rescript-app
```

or

```sh
pnpm create rescript-app@latest
```

or

```sh
bun create rescript-app
```

You can also skip the interactive prompts by passing a project name and template flag.
Supported templates are defined [`here`](./src/Templates.res).

With npm, pass the template flag after `--`:

```sh
npm create rescript-app@latest my-app -- --template vite
```

With Yarn, pnpm, and Bun, you can pass the template flag directly:

```sh
yarn create rescript-app my-app --template vite
```

## Add to existing project

If you have an existing JavaScript project containing a `package.json`, you can execute one of the above commands directly in your project's directory to add ReScript to your project.
