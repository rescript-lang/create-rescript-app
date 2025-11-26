open Node

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

let defaultPackagerInfo = {packageManager: Npm, command: "npm"}

@scope(("process", "env"))
external npm_execpath: option<string> = "npm_execpath"

let getPackageManagerInfo = async () =>
  switch npm_execpath {
  | None => defaultPackagerInfo
  | Some(execPath) =>
    // #58: Windows: packageManager may be something like
    // "C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js".
    //
    // Therefore, packageManager needs to be in quotes, and we need to prepend "node "
    // if packageManager points to a JS file, otherwise the invocation will hang.
    let maybeNode = execPath->String.endsWith("js") ? "node " : ""
    let command = `${maybeNode}"${execPath}"`

    // Note: exec path may be something like
    // /usr/local/lib/node_modules/npm/bin/npm-cli.js
    // So we have to check for substrings here.
    let filename = Path.parse(execPath).name->String.toLowerCase

    let packageManager = switch () {
    | _ if filename->String.includes("npm") => Some(Npm)
    | _ if filename->String.includes("yarn") =>
      let versionResult = await Promisified.ChildProcess.exec(`${command} --version`)
      let version = versionResult.stdout->String.trim
      let isYarn1 = CompareVersions.compareVersions(version, "2.0.0")->Ordering.isLess

      Some(isYarn1 ? Yarn1 : YarnBerry)
    | _ if filename->String.includes("pnpm") => Some(Pnpm)
    | _ if filename->String.includes("bun") => Some(Bun)
    | _ => None
    }

    switch packageManager {
    | Some(packageManager) => {packageManager, command}
    | None => defaultPackagerInfo
    }
  }
