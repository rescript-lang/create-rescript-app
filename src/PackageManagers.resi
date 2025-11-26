type packageManager =
  | Npm
  | Yarn1
  | YarnBerry
  | Pnpm
  | Bun

type packageManagerInfo = {
  packageManager: packageManager,
  command: string,
}

let getPackageManagerInfo: unit => promise<packageManagerInfo>
