open Node

module P = ClackPrompts

let rescriptVersionRange = `11.1.4 || 12.x.x`
let finalRescriptCoreVersion = "1.6.1"
let includesRewatchVersionRange = ">=12.0.0-alpha.15"
let includesStdlibVersionRange = ">=12.0.0-beta.1"

type versions = {rescriptVersion: string, rescriptCoreVersion: option<string>}

let spinnerMessage = "Loading available versions..."

let promptVersions = async () => {
  let s = P.spinner()

  s->P.Spinner.start(spinnerMessage)

  let rescriptVersionsResult = await NpmRegistry.getPackageVersions(
    "rescript",
    rescriptVersionRange,
  )

  switch rescriptVersionsResult {
  | Ok(_) => s->P.Spinner.stop("Versions loaded.")
  | Error(_) => s->P.Spinner.stop(spinnerMessage)
  }

  let rescriptVersion = switch rescriptVersionsResult {
  | Ok([version]) => version
  | Ok(rescriptVersions) =>
    let options = rescriptVersions->Array.map(v => {P.value: v})

    let initialValue = None
    // Reactivate for v13 alpha -> first non-alpha/beta/rc version should be the default
    // options->Array.find(o => o.value->String.startsWith("12."))->Option.map(o => o.value)

    let selectOptions = {ClackPrompts.message: "ReScript version?", options, ?initialValue}

    await P.select(selectOptions)->P.resultOrRaise
  | Error(error) => error->NpmRegistry.getFetchErrorMessage->JsError.throwWithMessage
  }

  let includesStdlib = CompareVersions.satisfies(rescriptVersion, includesStdlibVersionRange)
  let rescriptCoreVersion = includesStdlib ? None : Some(finalRescriptCoreVersion)

  {rescriptVersion, rescriptCoreVersion}
}

let ensureYarnNodeModulesLinker = async () => {
  let yarnRcPath = Path.join2(Process.cwd(), ".yarnrc.yml")

  if !Fs.existsSync(yarnRcPath) {
    let nodeLinkerLine = "nodeLinker: node-modules"
    let eol = Os.eol

    await Fs.Promises.writeFile(yarnRcPath, `${nodeLinkerLine}${eol}`)
  }
}

let removeNpmPackageLock = async () => {
  let packageLockPath = Path.join2(Process.cwd(), "package-lock.json")

  if Fs.existsSync(packageLockPath) {
    await Fs.Promises.unlink(packageLockPath)
  }
}

let installVersions = async ({rescriptVersion, rescriptCoreVersion}) => {
  let packageManagerInfo = await PackageManagers.getPackageManagerInfo()
  let {packageManager} = packageManagerInfo

  let execCommand = async command => {
    let fullCommand = `${packageManagerInfo.command} ${command}`
    let _ = await Promisified.ChildProcess.exec(fullCommand)
  }

  let packages = switch rescriptCoreVersion {
  | Some(rescriptCoreVersion) => [
      `rescript@${rescriptVersion}`,
      `@rescript/core@${rescriptCoreVersion}`,
    ]
  | None => [`rescript@${rescriptVersion}`]
  }

  switch packageManager {
  | YarnBerry => await ensureYarnNodeModulesLinker()
  | Pnpm => await execCommand("import") // import versions from package-lock.json
  | _ => ()
  }

  await execCommand(`add ${packages->Array.join(" ")}`)

  if packageManager !== Npm {
    await removeNpmPackageLock()
  }
}

let usesRewatch = ({rescriptVersion}) =>
  CompareVersions.satisfies(rescriptVersion, includesRewatchVersionRange)
