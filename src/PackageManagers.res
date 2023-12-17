@scope(("process", "env"))
external execpath: option<string> = "npm_execpath"

// pnpm must be before npm in this array, as npm is a substring of it
let packageManagers = ["pnpm", "npm", "yarn", "bun"]
let defaultPackageManager = "npm"

let getActivePackageManager = () =>
  execpath
  ->Option.flatMap(execpath => packageManagers->Array.find(pm => execpath->String.includes(pm)))
  ->Option.getOr(defaultPackageManager)
