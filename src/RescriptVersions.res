open Node

module P = ClackPrompts

let rescriptVersionRange = `11.x.x || 12.x.x`
let rescriptCoreVersionRange = ">=1.0.0"
let includesRewatchVersionRange = ">=12.0.0-alpha.15"
let includesStdlibVersionRange = ">=12.0.0-beta.1"

type versions = {rescriptVersion: string, rescriptCoreVersion: option<string>}

let getCompatibleRescriptCoreVersions = (~rescriptVersion, ~rescriptCoreVersions) =>
  if CompareVersions.compareVersions(rescriptVersion, "11.1.0")->Ordering.isLess {
    rescriptCoreVersions->Array.filter(coreVersion =>
      CompareVersions.compareVersions(coreVersion, "1.3.0")->Ordering.isLess
    )
  } else {
    rescriptCoreVersions
  }

let spinnerMessage = "Loading available versions..."

let promptVersions = async () => {
  let s = P.spinner()

  s->P.Spinner.start(spinnerMessage)

  let (rescriptVersionsResult, rescriptCoreVersionsResult) = await Promise.all2((
    NpmRegistry.getPackageVersions("rescript", rescriptVersionRange),
    NpmRegistry.getPackageVersions("@rescript/core", rescriptCoreVersionRange),
  ))

  switch (rescriptVersionsResult, rescriptCoreVersionsResult) {
  | (Ok(_), Ok(_)) => s->P.Spinner.stop("Versions loaded.")
  | _ => s->P.Spinner.stop(spinnerMessage)
  }

  let rescriptVersion = switch rescriptVersionsResult {
  | Ok([version]) => version
  | Ok(rescriptVersions) =>
    let options = rescriptVersions->Array.map(v => {P.value: v})

    let initialValue =
      options->Array.find(o => o.value->String.startsWith("12."))->Option.map(o => o.value)

    let selectOptions = {ClackPrompts.message: "ReScript version?", options, ?initialValue}

    await P.select(selectOptions)->P.resultOrRaise
  | Error(error) => error->NpmRegistry.getFetchErrorMessage->JsError.throwWithMessage
  }

  let rescriptCoreVersions = switch rescriptCoreVersionsResult {
  | Ok(versions) => versions
  | Error(error) => error->NpmRegistry.getFetchErrorMessage->JsError.throwWithMessage
  }

  let rescriptCoreVersions = getCompatibleRescriptCoreVersions(
    ~rescriptVersion,
    ~rescriptCoreVersions,
  )

  let includesStdlib = CompareVersions.satisfies(rescriptVersion, includesStdlibVersionRange)

  let rescriptCoreVersion = switch rescriptCoreVersions {
  | _ if includesStdlib => None
  | [version] => Some(version)
  | _ =>
    let version = await P.select({
      message: "ReScript Core version?",
      options: rescriptCoreVersions->Array.map(v => {P.value: v}),
    })->P.resultOrRaise
    Some(version)
  }

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

let esmModuleSystemName = ({rescriptVersion}) =>
  CompareVersions.compareVersions(rescriptVersion, "11.1.0-rc.8") > 0. ? "esmodule" : "es6"

let usesRewatch = ({rescriptVersion}) =>
  CompareVersions.satisfies(rescriptVersion, includesRewatchVersionRange)
