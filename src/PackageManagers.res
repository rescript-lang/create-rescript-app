@scope(("process", "env"))
external execpath: option<string> = "npm_execpath"

let packageManagers = ["npm", "pnpm", "yarn", "bun"]
let defaultPackageManager = "npm"

let getActivePackageManager = () =>
  execpath
  ->Option.flatMap(execpath => packageManagers->Array.find(pm => execpath->String.includes(pm)))
  ->Option.getOr(defaultPackageManager)
