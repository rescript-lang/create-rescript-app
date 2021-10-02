# create-rescript-app

Create ReScript apps with no build configuration.

## Quick Start

```sh
npx create-rescript-app my-app
cd my-app
npm start
```

## Install options

| Template                         | short cmd |    long cmd |
| :------------------------------- | :-------: | ----------: |
| Basic                            |    -b     |     --basic |
| Default / CRA equivalent (React) |    -d     |   --default |
| NextJS                           |    -nx    |    --nextjs |
| GraphQL                          |   -gql    |   --graphql |
| Storybook                        |    -sb    | --storybook |

### Bootstrap a ReScript app with Graphql

```sh
npx create-rescript-app my-app -gql
```

### Bootstrap a ReScript app with Storybook

```sh
npx create-rescript-app my-app -sb
```

### Bootstrap a NextJS app with ReScript

```sh
npx create-rescript-app my-app -nx
```
