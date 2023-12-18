open Node

@scope(("process", "env"))
external npm_execpath: option<string> = "npm_execpath"

let compatiblePackageManagers = ["pnpm", "npm", "yarn", "bun"]

let isCompatiblePackageManager = execPath => {
  let filename = Path.parse(execPath).name

  // Note: exec path may be something like
  // /usr/local/lib/node_modules/npm/bin/npm-cli.js
  // So we have to check for substrings here.
  compatiblePackageManagers->Array.some(pm => filename->String.includes(pm))
}

let getActivePackageManager = () =>
  switch npm_execpath {
  | Some(execPath) if isCompatiblePackageManager(execPath) => execPath
  | _ => "npm"
  }
